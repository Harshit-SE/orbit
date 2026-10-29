import asyncio
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch

from orbit_agent.evidence import render_note_preview
from orbit_agent.task_runner import _search_web, parse_action, parse_note, run_task


class AgentTaskTests(unittest.IsolatedAsyncioTestCase):
    def test_allowlist_parser_rejects_other_actions(self) -> None:
        self.assertEqual(parse_note("Create note: Hello world"), ("Hello world", "Hello world"))
        self.assertIsNone(parse_note("Open a browser and research"))
        self.assertIsNone(parse_note("Create note:"))
        self.assertEqual(parse_action("List notes"), ("list_notes", ""))
        self.assertEqual(parse_action("Find note: presentation"), ("find_note", "presentation"))
        self.assertEqual(parse_action("Research: how do solar panels work"), ("research_web", "how do solar panels work"))
        self.assertIsNone(parse_action("Delete all notes"))

    def test_web_results_keep_only_unique_https_sources(self) -> None:
        class FakeDDGS:
            def __init__(self, timeout):
                self.timeout = timeout

            def text(self, query, **kwargs):
                self.asserted_query = query
                return [
                    {"title": "Solar energy", "href": "https://example.edu/solar", "body": "How solar panels produce electricity."},
                    {"title": "Insecure", "href": "http://example.net/page", "body": "Drop this."},
                    {"title": "Duplicate host", "href": "https://example.edu/another", "body": "Drop duplicate."},
                    {"title": "Clean energy", "href": "https://example.org/clean", "body": "Solar power information."},
                ]

        with patch.dict("sys.modules", {"ddgs": types.SimpleNamespace(DDGS=FakeDDGS)}):
            result = _search_web("solar panels")
        self.assertIn("https://example.edu/solar", result)
        self.assertIn("https://example.org/clean", result)
        self.assertNotIn("http://example.net/page", result)
        self.assertNotIn("another", result)

    async def test_list_and_find_read_only_notes_in_the_approved_folder(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root) / "demo"
            folder.mkdir()
            (folder / "note-one.md").write_text("# Presentation\n\nOrbit demo plan", "utf-8")
            outside = Path(root) / "note-outside.md"
            outside.write_text("# Secret\n\nDo not expose", "utf-8")
            with patch("orbit_agent.permissions.DEMO_FOLDER", folder):
                sent = []

                async def send(payload):
                    sent.append(payload)

                await run_task({"id": "list-task", "request": "List notes"}, asyncio.Event(), send)
                self.assertEqual(sent[-1]["type"], "completed")
                self.assertIn("note-one.md", sent[-1]["result"])
                self.assertNotIn("Secret", sent[-1]["result"])

                await run_task({"id": "find-task", "request": "Find note: demo plan"}, asyncio.Event(), send)
                self.assertIn("note-one.md", sent[-1]["result"])
                self.assertIn("Orbit demo plan", sent[-1]["result"])
                self.assertNotIn("evidence", sent[-1])

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

    async def test_research_returns_source_links_as_a_completed_task(self) -> None:
        sent = []

        async def send(payload):
            sent.append(payload)

        with patch("orbit_agent.task_runner._search_web", return_value="Web results for: demo\n\n1. Official source\nhttps://example.gov/page\nRelevant snippet"):
            await run_task({"id": "research-task", "request": "Research: demo topic"}, asyncio.Event(), send)
        self.assertEqual(sent[-1]["type"], "completed")
        self.assertIn("https://example.gov/page", sent[-1]["result"])
        self.assertEqual(sent[-1]["step"], "Found relevant public webpages")
        self.assertNotIn("evidence", sent[-1])

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
