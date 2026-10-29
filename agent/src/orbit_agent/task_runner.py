from __future__ import annotations

import asyncio
import base64
import re
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any

from orbit_agent.evidence import render_note_preview
from orbit_agent.permissions import note_path

Send = Callable[[dict[str, Any]], Awaitable[None]]


def parse_note(request: str) -> tuple[str, str] | None:
    match = re.match(r"(?is)^\s*create\s+note\s*:\s*(.+?)\s*$", request)
    if not match:
        return None
    content = match.group(1).strip()
    if not content:
        return None
    title = content.splitlines()[0].strip()[:64] or "Orbit note"
    return title, content


async def run_task(task: dict[str, str], stop_event: asyncio.Event, send: Send) -> None:
    task_id = task["id"]
    parsed = parse_note(task.get("request", ""))
    if parsed is None:
        await send({"type": "failed", "task_id": task_id, "error": "Unsupported action. Only Create note: <text> is allowed."})
        return
    title, content = parsed
    steps = [
        (0.12, "Validating the Create note action"),
        (0.34, "Checking the approved Orbit Demo folder"),
        (0.58, "Preparing the note file"),
    ]
    for progress, step in steps:
        if stop_event.is_set():
            await send({"type": "stopped", "task_id": task_id})
            return
        await send({"type": "progress", "task_id": task_id, "progress": progress, "step": step})
        try:
            await asyncio.wait_for(stop_event.wait(), timeout=0.65)
            await send({"type": "stopped", "task_id": task_id})
            return
        except TimeoutError:
            pass
    try:
        target: Path = note_path(task_id)
        if stop_event.is_set():
            await send({"type": "stopped", "task_id": task_id})
            return
        await asyncio.to_thread(target.write_text, f"# {title}\n\n{content}\n", "utf-8")
        preview = await asyncio.to_thread(render_note_preview, title, content)
        await send({
            "type": "completed",
            "task_id": task_id,
            "result": str(target.name),
            "evidence": {
                "kind": "note_preview",
                "mime_type": "image/png",
                "content_base64": base64.b64encode(preview).decode("ascii"),
            },
        })
    except Exception as exc:
        await send({"type": "failed", "task_id": task_id, "error": f"Could not create the approved demo note: {exc}"})
