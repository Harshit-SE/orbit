import tempfile
import unittest
from pathlib import Path

from app.services.store import TaskStore


class TaskStoreTests(unittest.TestCase):
    def test_task_updates_and_events_persist(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            store = TaskStore(Path(root))
            created = store.create("Create note", "Create note: Hello", "queued", "Waiting for agent")
            running = store.update(created["id"], status="running", step="Writing note", progress=0.5)
            completed = store.update(created["id"], status="completed", step="Done", progress=1)

            self.assertEqual(running["progress"], 0.5)
            self.assertEqual(completed["status"], "completed")
            self.assertEqual(len(store.list()), 1)
            self.assertEqual([event["message"] for event in store.get(created["id"])["events"]], [
                "Waiting for agent", "Writing note", "Done"
            ])

    def test_evidence_is_private_and_retrievable_by_id(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            store = TaskStore(Path(root))
            task = store.create("Create note", "Create note: Hello", "queued", "Waiting")
            item = store.add_evidence(task["id"], "image/png", "note_preview", b"png-data")
            path, mime_type = store.evidence_path(item["id"])
            self.assertTrue(path.is_relative_to(Path(root)))
            self.assertEqual(mime_type, "image/png")
            self.assertEqual(path.read_bytes(), b"png-data")


if __name__ == "__main__":
    unittest.main()
