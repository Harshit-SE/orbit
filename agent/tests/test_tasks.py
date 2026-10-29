import asyncio
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from orbit_agent.evidence import render_note_preview
from orbit_agent.task_runner import parse_note, run_task


class AgentTaskTests(unittest.IsolatedAsyncioTestCase):
    def test_allowlist_parser_rejects_other_actions(self) -> None:
        self.assertEqual(parse_note("Create note: Hello world"), ("Hello world", "Hello world"))
        self.assertIsNone(parse_note("Open a browser and research"))
        self.assertIsNone(parse_note("Create note:"))

    async def test_note_write_and_preview_use_only_demo_folder(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root) / "demo"
            folder.mkdir()
            with patch("orbit_agent.task_runner.note_path", side_effect=lambda task_id: folder / f"note-{task_id}.md"):
                sent = []

                async def send(payload):
                    sent.append(payload)

                await run_task({"id": "demo-task", "request": "Create note: Hello from Orbit"}, asyncio.Event(), send)
                note = folder / "note-demo-task.md"
                self.assertTrue(note.is_file())
                self.assertIn("Hello from Orbit", note.read_text())
                self.assertEqual(sent[-1]["type"], "completed")
                self.assertEqual(sent[-1]["evidence"]["mime_type"], "image/png")
                self.assertTrue(render_note_preview("Note", "Content").startswith(b"\x89PNG"))

    async def test_stop_prevents_the_note_write(self) -> None:
        stop = asyncio.Event()
        sent = []

        async def send(payload):
            sent.append(payload)
            if payload["type"] == "progress":
                stop.set()

        await run_task({"id": "demo-task", "request": "Create note: Hello"}, stop, send)
        self.assertEqual(sent[-1]["type"], "stopped")


if __name__ == "__main__":
    unittest.main()
