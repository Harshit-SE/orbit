from __future__ import annotations

import asyncio
import json
import os
from typing import Any
from urllib.parse import urlparse, urlunparse

import websockets

from orbit_agent.task_runner import run_task


def websocket_url() -> str:
    base = os.environ.get("ORBIT_API_URL", "ws://127.0.0.1:8765").rstrip("/")
    parsed = urlparse(base)
    scheme = {"http": "ws", "https": "wss", "ws": "ws", "wss": "wss"}.get(parsed.scheme)
    if scheme is None or not parsed.netloc:
        raise ValueError("ORBIT_API_URL must be an http(s) or ws(s) URL")
    return urlunparse((scheme, parsed.netloc, "/v1/agent", "", "", ""))


async def _session() -> None:
    token = os.environ.get("ORBIT_AGENT_TOKEN", "")
    if len(token) < 24:
        raise RuntimeError("Set ORBIT_AGENT_TOKEN to the backend agent token (at least 24 characters)")
    running: dict[str, tuple[asyncio.Task[None], asyncio.Event]] = {}

    async def send(websocket: Any, payload: dict[str, Any]) -> None:
        await websocket.send(json.dumps(payload))

    async with websockets.connect(
        websocket_url(),
        additional_headers={"Authorization": f"Bearer {token}"},
        ping_interval=20,
        ping_timeout=20,
        max_size=3_000_000,
    ) as websocket:
        print("Connected to Orbit backend. Waiting for allowlisted tasks.", flush=True)
        async for raw in websocket:
            message = json.loads(raw)
            if message.get("type") == "execute":
                task = message.get("task", {})
                task_id = task.get("id")
                if not task_id or task_id in running:
                    continue
                stop_event = asyncio.Event()
                worker = asyncio.create_task(run_task(task, stop_event, lambda payload: send(websocket, payload)))
                running[task_id] = (worker, stop_event)
                worker.add_done_callback(lambda _, key=task_id: running.pop(key, None))
            elif message.get("type") == "stop":
                entry = running.get(message.get("task_id", ""))
                if entry:
                    entry[1].set()
        for worker, stop_event in running.values():
            stop_event.set()
            worker.cancel()


async def run_forever() -> None:
    delay = 1
    while True:
        try:
            await _session()
            delay = 1
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            print(f"Orbit connection ended: {exc}. Retrying in {delay}s.", flush=True)
            await asyncio.sleep(delay)
            delay = min(delay * 2, 20)
