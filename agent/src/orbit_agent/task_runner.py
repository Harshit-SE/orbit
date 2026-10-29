from __future__ import annotations

import asyncio
import base64
import re
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from orbit_agent.evidence import render_note_preview
from orbit_agent.permissions import note_path, safe_note_files

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


def parse_action(request: str) -> tuple[str, str] | None:
    note = parse_note(request)
    if note is not None:
        return "create_note", note[1]
    if re.fullmatch(r"\s*list\s+notes\s*", request, re.IGNORECASE):
        return "list_notes", ""
    match = re.fullmatch(r"\s*find\s+note\s*:\s*(.{1,100}?)\s*", request, re.IGNORECASE | re.DOTALL)
    if match:
        return "find_note", match.group(1).strip()
    match = re.fullmatch(r"\s*research\s*:\s*(.{3,500}?)\s*", request, re.IGNORECASE | re.DOTALL)
    if match:
        return "research_web", match.group(1).strip()
    return None


def _list_notes() -> str:
    notes = safe_note_files()
    if not notes:
        return "No Orbit notes found in the approved folder."
    lines = ["Orbit notes in the approved folder:"]
    lines.extend(f"• {path.name} — {path.read_text('utf-8').splitlines()[0].removeprefix('# ').strip()[:80]}" for path in notes[:20])
    if len(notes) > 20:
        lines.append(f"…and {len(notes) - 20} more")
    return "\n".join(lines)


def _find_notes(query: str) -> str:
    matches: list[str] = []
    needle = query.casefold()
    for path in safe_note_files():
        try:
            content = path.read_text("utf-8")[:100_000]
        except (OSError, UnicodeError):
            continue
        index = content.casefold().find(needle)
        if index >= 0:
            start, end = max(0, index - 45), min(len(content), index + len(query) + 85)
            excerpt = " ".join(content[start:end].split())
            matches.append(f"• {path.name}: …{excerpt}…")
            if len(matches) == 10:
                break
    return "Matching Orbit notes:\n" + "\n".join(matches) if matches else f"No Orbit notes matched “{query}”."


def _search_web(query: str) -> str:
    """Return a few public search-result snippets and HTTPS source links."""
    from ddgs import DDGS

    results = DDGS(timeout=10).text(query, region="in-en", max_results=8, safesearch="moderate")
    sources: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for item in results:
        title = " ".join(str(item.get("title", "")).split())[:180]
        url = str(item.get("href", "")).strip()
        snippet = " ".join(str(item.get("body", "")).split())[:500]
        parsed = urlparse(url)
        if not title or parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.hostname in seen:
            continue
        sources.append((title, url[:1500], snippet))
        seen.add(parsed.hostname)
        if len(sources) == 3:
            break
    if not sources:
        return "No suitable webpages were found. Try a more specific research question."
    lines = [
        f'Web results for: {query}',
        "These are search-engine summaries. Open the source links to read the full pages.",
        "",
    ]
    for index, (title, url, snippet) in enumerate(sources, 1):
        lines.extend([f"{index}. {title}", url, snippet or "No preview text was provided.", ""])
    return "\n".join(lines).strip()


async def run_task(task: dict[str, str], stop_event: asyncio.Event, send: Send) -> None:
    task_id = task["id"]
    parsed = parse_action(task.get("request", ""))
    if parsed is None:
        await send({"type": "failed", "task_id": task_id, "error": "Unsupported action. Try Research: <question>, Create note: <text>, List notes, or Find note: <text>."})
        return
    action, argument = parsed
    title = argument.splitlines()[0].strip()[:64] if action == "create_note" else ""
    content = argument
    if action == "research_web":
        steps = [
            (0.12, "Validating the research question"),
            (0.34, "Preparing a public web search"),
            (0.58, "Getting relevant webpages"),
        ]
    else:
        steps = [
            (0.12, "Validating the requested Orbit notes action"),
            (0.34, "Checking the approved Orbit Demo folder"),
            (0.58, "Preparing the result"),
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
        evidence = None
        if action == "create_note":
            target: Path = note_path(task_id)
            if stop_event.is_set():
                await send({"type": "stopped", "task_id": task_id})
                return
            await asyncio.to_thread(target.write_text, f"# {title}\n\n{content}\n", "utf-8")
            preview = await asyncio.to_thread(render_note_preview, title, content)
            result = f"Created {target.name} in the approved Orbit folder."
            evidence = {
                "kind": "note_preview",
                "mime_type": "image/png",
                "content_base64": base64.b64encode(preview).decode("ascii"),
            }
        elif action == "list_notes":
            result = await asyncio.to_thread(_list_notes)
        elif action == "find_note":
            result = await asyncio.to_thread(_find_notes, argument)
        else:
            await send({"type": "progress", "task_id": task_id, "progress": 0.72, "step": "Searching public webpages for relevant sources"})
            if stop_event.is_set():
                await send({"type": "stopped", "task_id": task_id})
                return
            search = asyncio.create_task(asyncio.to_thread(_search_web, argument))
            stop_wait = asyncio.create_task(stop_event.wait())
            done, _ = await asyncio.wait({search, stop_wait}, timeout=25, return_when=asyncio.FIRST_COMPLETED)
            stop_wait.cancel()
            await asyncio.gather(stop_wait, return_exceptions=True)
            if stop_event.is_set():
                search.cancel()
                await send({"type": "stopped", "task_id": task_id})
                return
            if search not in done:
                search.cancel()
                raise TimeoutError("Web search timed out after 25 seconds")
            result = search.result()
        step = {
            "create_note": "Created note in the approved folder",
            "list_notes": "Listed notes in the approved folder",
            "find_note": "Searched notes in the approved folder",
            "research_web": "Found relevant public webpages",
        }[action]
        payload = {"type": "completed", "task_id": task_id, "result": result, "step": step}
        if evidence is not None:
            payload["evidence"] = evidence
        await send(payload)
    except Exception as exc:
        await send({"type": "failed", "task_id": task_id, "error": f"Could not complete the requested Orbit action: {exc}"})
