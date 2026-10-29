"""Manual live-service smoke check; start backend and agent first."""

from __future__ import annotations

import json
import os
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen


BASE_URL = os.environ.get("ORBIT_TEST_BASE_URL", "http://127.0.0.1:8765")
TOKEN = os.environ["ORBIT_MOBILE_TOKEN"]


def call(path: str, method: str = "GET", body: dict | None = None, token: str = TOKEN) -> tuple[int, object, bytes]:
    data = json.dumps(body).encode() if body is not None else None
    request = Request(
        f"{BASE_URL}{path}",
        data=data,
        method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        response = urlopen(request, timeout=5)
    except HTTPError as exc:
        response = exc
    payload = response.read()
    if response.headers.get_content_type() == "application/json" and payload:
        decoded: object = json.loads(payload)
    else:
        decoded = payload
    return response.status, decoded, payload


def wait_for(task_id: str, expected: str, timeout: float = 15) -> dict:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        status, task, _ = call(f"/v1/tasks/{task_id}")
        assert status == 200, task
        if task["status"] in {"completed", "failed", "stopped"}:
            assert task["status"] == expected, task
            return task
        time.sleep(0.25)
    raise AssertionError(f"Task {task_id} did not finish as {expected}")


def main() -> None:
    status, health, _ = call("/health")
    assert status == 200 and health["agent_online"], health
    status, _, _ = call("/v1/tasks", token="invalid-demo-token")
    assert status == 401, f"Expected unauthorized response, received {status}"

    status, unsupported, _ = call("/v1/tasks", "POST", {"request": "Open a browser"})
    assert status == 200 and unsupported["status"] == "failed", unsupported

    status, created, _ = call("/v1/tasks", "POST", {"request": "Create note: Orbit end-to-end smoke test"})
    assert status == 200 and created["status"] == "queued", created
    completed = wait_for(created["id"], "completed")
    assert completed["progress"] == 1.0 and completed["evidence"], completed
    assert any(event["kind"] == "progress" for event in completed["events"]), completed["events"]
    status, _, image = call(completed["evidence"][0]["url"])
    assert status == 200 and image.startswith(b"\x89PNG\r\n\x1a\n"), "note-preview evidence is not a PNG"

    status, listed, _ = call("/v1/tasks", "POST", {"request": "List notes"})
    assert status == 200 and listed["status"] == "queued", listed
    listed = wait_for(listed["id"], "completed")
    assert "Orbit end-to-end smoke test" in listed["result"], listed

    status, found, _ = call("/v1/tasks", "POST", {"request": "Find note: end-to-end smoke"})
    assert status == 200 and found["status"] == "queued", found
    found = wait_for(found["id"], "completed")
    assert "note-" in found["result"] and "end-to-end smoke" in found["result"], found

    status, research, _ = call("/v1/tasks", "POST", {"request": "Research: NASA solar eclipse official information"})
    assert status == 200 and research["status"] == "queued", research
    research = wait_for(research["id"], "completed", timeout=30)
    assert "Web results for:" in research["result"] and "https://" in research["result"], research

    status, pending, _ = call("/v1/tasks", "POST", {"request": "Create note: This note should be stopped"})
    assert status == 200, pending
    status, stopped, _ = call(f"/v1/tasks/{pending['id']}/stop", "POST")
    assert status == 200, stopped
    stopped = wait_for(pending["id"], "stopped")
    note_file = Path(__file__).resolve().parents[2] / "agent" / "demo_folder" / f"note-{pending['id']}.md"
    assert not note_file.exists(), f"A stopped task wrote a file: {note_file}"
    print("E2E passed: auth, unsupported task, create/list/find notes, public web research, progress/completion, evidence, and Stop.")


if __name__ == "__main__":
    main()
