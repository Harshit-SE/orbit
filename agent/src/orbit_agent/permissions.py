from __future__ import annotations

import os
from pathlib import Path


DEFAULT_DEMO_FOLDER = Path(__file__).resolve().parents[2] / "demo_folder"
DEMO_FOLDER = Path(os.environ.get("ORBIT_DEMO_FOLDER", str(DEFAULT_DEMO_FOLDER))).expanduser().resolve()


def note_path(task_id: str) -> Path:
    """Return a deterministic Markdown path inside the single approved folder."""
    if not task_id or any(character not in "0123456789abcdef-" for character in task_id.lower()):
        raise ValueError("Invalid task id")
    DEMO_FOLDER.mkdir(parents=True, exist_ok=True)
    path = (DEMO_FOLDER / f"note-{task_id}.md").resolve()
    if path.parent != DEMO_FOLDER or path.suffix.lower() != ".md":
        raise PermissionError("Resolved note path escaped the approved demo folder")
    return path


def safe_note_files(limit: int = 100) -> list[Path]:
    """Return only Orbit-created Markdown notes whose resolved paths stay in scope."""
    DEMO_FOLDER.mkdir(parents=True, exist_ok=True)
    notes: list[Path] = []
    for candidate in DEMO_FOLDER.glob("note-*.md"):
        try:
            resolved = candidate.resolve(strict=True)
            if resolved.parent == DEMO_FOLDER and resolved.is_file():
                notes.append(resolved)
        except (OSError, RuntimeError):
            continue
    return sorted(notes, key=lambda path: path.stat().st_mtime, reverse=True)[:limit]
