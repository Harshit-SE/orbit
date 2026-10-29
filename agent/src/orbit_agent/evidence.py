from __future__ import annotations

from io import BytesIO

from PIL import Image, ImageDraw, ImageFont


def render_note_preview(title: str, content: str) -> bytes:
    """Render a scoped note preview image; never captures unrelated desktop content."""
    image = Image.new("RGB", (960, 620), "#111827")
    draw = ImageDraw.Draw(image)
    try:
        title_font = ImageFont.truetype("arial.ttf", 32)
        body_font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        title_font = ImageFont.load_default()
        body_font = ImageFont.load_default()

    draw.rounded_rectangle((38, 38, 922, 582), radius=22, fill="#1B2638", outline="#8B7CFF", width=2)
    draw.text((72, 72), "ORBIT · NOTE PREVIEW", fill="#57D6B3", font=body_font)
    safe_title = title.encode("ascii", "replace").decode("ascii")[:64]
    draw.text((72, 130), safe_title, fill="#F4F6FA", font=title_font)
    safe_content = content.encode("ascii", "replace").decode("ascii")
    y = 200
    for line in _wrap(safe_content, 72)[:12]:
        draw.text((72, y), line, fill="#A7B1C2", font=body_font)
        y += 32
    draw.text((72, 530), "Generated preview of the note saved in Orbit Demo", fill="#8B7CFF", font=body_font)
    result = BytesIO()
    image.save(result, format="PNG", optimize=True)
    return result.getvalue()


def _wrap(text: str, width: int) -> list[str]:
    lines: list[str] = []
    for paragraph in text.splitlines() or [text]:
        words = paragraph.split()
        line = ""
        for word in words:
            candidate = f"{line} {word}".strip()
            if len(candidate) > width and line:
                lines.append(line)
                line = word
            else:
                line = candidate
        lines.append(line)
    return lines
