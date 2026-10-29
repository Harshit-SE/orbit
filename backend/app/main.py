from __future__ import annotations

import asyncio
import base64
import binascii
import hmac
import json
import os
import re
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Header, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from app.services.store import TaskStore


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = Path(os.environ.get("ORBIT_DATA_DIR", str(ROOT / "storage"))).resolve()
store = TaskStore(DATA_DIR)
app = FastAPI(title="Orbit API", version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)


class SubmitTask(BaseModel):
    request: str = Field(min_length=1, max_length=5000)


class Hub:
    def __init__(self) -> None:
        self.agent: WebSocket | None = None
        self.send_lock = asyncio.Lock()
        self.subscribers: set[asyncio.Queue[dict[str, Any]]] = set()

    async def publish(self, task: dict[str, Any]) -> None:
        event = {"type": "task.updated", "task": task}
        for queue in tuple(self.subscribers):
            if queue.full():
                try:
                    queue.get_nowait()
                except asyncio.QueueEmpty:
                    pass
            queue.put_nowait(event)

    async def dispatch(self, task_id: str) -> bool:
        async with self.send_lock:
            if self.agent is None:
                return False
            task = store.get(task_id)
            if task is None or task["status"] != "queued":
                return False
            await self.agent.send_json({
                "type": "execute",
                "task": {"id": task["id"], "request": task["request"]},
            })
            return True


hub = Hub()


def _token_from_header(header: str | None) -> str:
    scheme, _, token = (header or "").partition(" ")
    return token if scheme.lower() == "bearer" else ""


def _expected_token(name: str) -> str:
    token = os.environ.get(name, "")
    if len(token) < 24:
        raise HTTPException(status_code=503, detail=f"Configure {name} with at least 24 characters")
    return token


def _authorize(header: str | None, name: str) -> None:
    expected = _expected_token(name)
    if not hmac.compare_digest(_token_from_header(header), expected):
        raise HTTPException(status_code=401, detail="Invalid bearer token")


def _task_title(request: str) -> tuple[str, str] | None:
    match = re.match(r"(?is)^\s*create\s+note\s*:\s*(.+?)\s*$", request)
    if not match:
        return None
    content = match.group(1).strip()
    if not content:
        return None
    first_line = content.splitlines()[0].strip()
    return (f"Create note · {first_line[:55] or 'Untitled'}", content)


@app.get("/health")
async def health() -> dict[str, Any]:
    return {"ok": True, "agent_online": hub.agent is not None, "service": "orbit-backend"}


@app.get("/v1/tasks")
async def list_tasks(authorization: str | None = Header(default=None)) -> list[dict[str, Any]]:
    _authorize(authorization, "ORBIT_MOBILE_TOKEN")
    return store.list()


@app.post("/v1/tasks")
async def submit_task(body: SubmitTask, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _authorize(authorization, "ORBIT_MOBILE_TOKEN")
    parsed = _task_title(body.request)
    if parsed is None:
        task = store.create(
            title=body.request[:80], request=body.request, status="failed",
            step="Unsupported request. Try: Create note: text for your note.",
            error="Only Create note: <text> is supported in this demo.",
        )
        await hub.publish(task)
        return task
    title, _ = parsed
    task = store.create(title=title, request=body.request, status="queued", step="Waiting for the Windows agent")
    if hub.agent is not None:
        try:
            await hub.dispatch(task["id"])
        except Exception:
            # Keep it queued; a reconnect will dispatch it.
            pass
    task = store.get(task["id"])
    await hub.publish(task or {})
    return task or {}


@app.get("/v1/tasks/{task_id}")
async def get_task(task_id: str, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _authorize(authorization, "ORBIT_MOBILE_TOKEN")
    task = store.get(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/v1/tasks/{task_id}/stop")
async def stop_task(task_id: str, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _authorize(authorization, "ORBIT_MOBILE_TOKEN")
    task = store.get(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if task["status"] in {"completed", "failed", "stopped"}:
        return task
    if task["status"] == "queued":
        updated = store.update(task_id, status="stopped", step="Stopped by you", event_kind="stopped")
        if hub.agent is not None:
            try:
                await hub.agent.send_json({"type": "stop", "task_id": task_id})
            except Exception:
                pass
        await hub.publish(updated or {})
        return updated or {}
    if hub.agent is not None:
        await hub.agent.send_json({"type": "stop", "task_id": task_id})
    return task


@app.get("/v1/evidence/{evidence_id}")
async def get_evidence(evidence_id: str, authorization: str | None = Header(default=None)) -> FileResponse:
    _authorize(authorization, "ORBIT_MOBILE_TOKEN")
    evidence = store.evidence_path(evidence_id)
    if evidence is None or not evidence[0].is_file():
        raise HTTPException(status_code=404, detail="Evidence not found")
    return FileResponse(evidence[0], media_type=evidence[1], filename=f"{evidence_id}.png")


@app.websocket("/v1/agent")
async def agent_socket(websocket: WebSocket) -> None:
    try:
        _authorize(websocket.headers.get("authorization"), "ORBIT_AGENT_TOKEN")
    except HTTPException:
        await websocket.close(code=4401, reason="Invalid agent token")
        return
    await websocket.accept()
    hub.agent = websocket
    try:
        for task in reversed(store.list(limit=100)):
            if task["status"] == "queued":
                await hub.dispatch(task["id"])
        async for raw in websocket.iter_text():
            if len(raw) > 3_000_000:
                await websocket.close(code=1009, reason="Message too large")
                break
            try:
                message = json.loads(raw)
            except json.JSONDecodeError:
                continue
            task_id = str(message.get("task_id", ""))
            kind = message.get("type")
            task = store.get(task_id)
            if task is None:
                continue
            if kind == "progress":
                updated = store.update(
                    task_id, status="running", step=str(message.get("step", "Working"))[:240],
                    progress=float(message.get("progress", 0)), event_kind="progress",
                )
            elif kind == "completed":
                evidence_message = message.get("evidence")
                if isinstance(evidence_message, dict):
                    content_value = evidence_message.get("content_base64", "")
                    try:
                        content = base64.b64decode(content_value, validate=True)
                    except (binascii.Error, ValueError):
                        content = b""
                    if len(content) <= 2_000_000 and evidence_message.get("mime_type") == "image/png" and content:
                        store.add_evidence(task_id, "image/png", "note_preview", content)
                updated = store.update(
                    task_id, status="completed", step="Created note in Orbit demo folder",
                    progress=1, result=str(message.get("result", ""))[:1000], event_kind="completed",
                )
            elif kind == "failed":
                updated = store.update(
                    task_id, status="failed", step=str(message.get("error", "Task failed"))[:240],
                    error=str(message.get("error", "Task failed"))[:1000], event_kind="failed",
                )
            elif kind == "stopped":
                updated = store.update(task_id, status="stopped", step="Stopped by you", event_kind="stopped")
            else:
                continue
            if updated:
                await hub.publish(updated)
    except WebSocketDisconnect:
        pass
    finally:
        if hub.agent is websocket:
            hub.agent = None
            for task in store.list(limit=100):
                if task["status"] == "running":
                    failed = store.update(
                        task["id"], status="failed", step="Windows agent disconnected during this task",
                        error="Agent connection closed before the task completed", event_kind="failed",
                    )
                    if failed:
                        await hub.publish(failed)


@app.websocket("/v1/events")
async def mobile_events(websocket: WebSocket) -> None:
    try:
        _authorize(websocket.headers.get("authorization"), "ORBIT_MOBILE_TOKEN")
    except HTTPException:
        await websocket.close(code=4401, reason="Invalid mobile token")
        return
    await websocket.accept()
    queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue(maxsize=100)
    hub.subscribers.add(queue)
    try:
        await websocket.send_json({"type": "agent.presence", "online": hub.agent is not None})
        while True:
            await websocket.send_json(await queue.get())
    except WebSocketDisconnect:
        pass
    finally:
        hub.subscribers.discard(queue)
