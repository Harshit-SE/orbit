from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator
from uuid import uuid4


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


class TaskStore:
    def __init__(self, data_dir: Path) -> None:
        self.data_dir = data_dir
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.db_path = self.data_dir / "orbit.sqlite3"
        self.evidence_dir = self.data_dir / "evidence"
        self.evidence_dir.mkdir(parents=True, exist_ok=True)
        with self._db() as db:
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS tasks (
                  id TEXT PRIMARY KEY, title TEXT NOT NULL, request TEXT NOT NULL,
                  status TEXT NOT NULL, step TEXT NOT NULL, progress REAL NOT NULL,
                  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
                  error TEXT, result TEXT
                );
                CREATE TABLE IF NOT EXISTS events (
                  id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT NOT NULL,
                  kind TEXT NOT NULL, message TEXT NOT NULL, occurred_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS evidence (
                  id TEXT PRIMARY KEY, task_id TEXT NOT NULL, kind TEXT NOT NULL,
                  mime_type TEXT NOT NULL, path TEXT NOT NULL, created_at TEXT NOT NULL
                );
                """
            )

    @contextmanager
    def _db(self) -> Iterator[sqlite3.Connection]:
        db = sqlite3.connect(self.db_path, timeout=10)
        db.row_factory = sqlite3.Row
        try:
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

    def create(self, title: str, request: str, status: str, step: str, error: str | None = None) -> dict[str, Any]:
        task_id = str(uuid4())
        timestamp = now()
        with self._db() as db:
            db.execute(
                "INSERT INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (task_id, title, request, status, step, 0.0, timestamp, timestamp, error, None),
            )
            db.execute(
                "INSERT INTO events(task_id,kind,message,occurred_at) VALUES(?,?,?,?)",
                (task_id, status, step, timestamp),
            )
        return self.get(task_id)  # type: ignore[return-value]

    def update(self, task_id: str, *, status: str | None = None, step: str | None = None,
               progress: float | None = None, error: str | None = None,
               result: str | None = None, event_kind: str | None = None) -> dict[str, Any] | None:
        with self._db() as db:
            row = db.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
            if row is None:
                return None
            new_status = status or row["status"]
            new_step = step or row["step"]
            new_progress = row["progress"] if progress is None else max(0.0, min(1.0, progress))
            new_error = error if error is not None else row["error"]
            new_result = result if result is not None else row["result"]
            timestamp = now()
            db.execute(
                "UPDATE tasks SET status=?,step=?,progress=?,updated_at=?,error=?,result=? WHERE id=?",
                (new_status, new_step, new_progress, timestamp, new_error, new_result, task_id),
            )
            if step is not None or status is not None or error is not None:
                db.execute(
                    "INSERT INTO events(task_id,kind,message,occurred_at) VALUES(?,?,?,?)",
                    (task_id, event_kind or new_status, new_step, timestamp),
                )
        return self.get(task_id)

    def add_evidence(self, task_id: str, mime_type: str, kind: str, content: bytes) -> dict[str, str]:
        evidence_id = str(uuid4())
        extension = ".png" if mime_type == "image/png" else ".bin"
        path = self.evidence_dir / f"{evidence_id}{extension}"
        path.write_bytes(content)
        created = now()
        with self._db() as db:
            db.execute(
                "INSERT INTO evidence VALUES(?,?,?,?,?,?)",
                (evidence_id, task_id, kind, mime_type, str(path), created),
            )
        return {"id": evidence_id, "task_id": task_id, "kind": kind, "mime_type": mime_type, "created_at": created}

    def get(self, task_id: str) -> dict[str, Any] | None:
        with self._db() as db:
            row = db.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
            if row is None:
                return None
            task = dict(row)
            task["events"] = [dict(item) for item in db.execute(
                "SELECT kind,message,occurred_at FROM events WHERE task_id=? ORDER BY id", (task_id,)
            ).fetchall()]
            task["evidence"] = [
                {"id": item["id"], "task_id": item["task_id"], "kind": item["kind"],
                 "mime_type": item["mime_type"], "created_at": item["created_at"],
                 "url": f"/v1/evidence/{item['id']}"}
                for item in db.execute("SELECT * FROM evidence WHERE task_id=? ORDER BY created_at", (task_id,)).fetchall()
            ]
            return task

    def list(self, limit: int = 100) -> list[dict[str, Any]]:
        with self._db() as db:
            ids = [row[0] for row in db.execute("SELECT id FROM tasks ORDER BY created_at DESC LIMIT ?", (limit,)).fetchall()]
        return [item for task_id in ids if (item := self.get(task_id)) is not None]

    def evidence_path(self, evidence_id: str) -> tuple[Path, str] | None:
        with self._db() as db:
            row = db.execute("SELECT path,mime_type FROM evidence WHERE id=?", (evidence_id,)).fetchone()
        if row is None:
            return None
        return Path(row["path"]), row["mime_type"]
