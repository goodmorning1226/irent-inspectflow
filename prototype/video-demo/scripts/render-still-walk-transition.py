"""Render a short, UI-free side-to-front walking transition from still images.

The effect intentionally keeps the scan holds perfectly stable.  During the
one-second move it uses eased crop motion, a short cross-view blend, and
horizontal motion trails to hide the otherwise hard cut between viewpoints.
It is a deterministic prototype composite, not generated camera geometry.
"""

from __future__ import annotations

import math
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
FRAME_DIR = ROOT / "prototype" / "mobile" / "assets" / "frames"
OUTPUT_DIR = ROOT / "prototype" / "video-demo" / "output"

SIDE_PATH = FRAME_DIR / "exterior_clean_source.png"
FRONT_PATH = FRAME_DIR / "vehicle_front.png"
OUTPUT_PATH = OUTPUT_DIR / "still-walk-side-to-front-test-3s.mp4"

WIDTH = 1920
HEIGHT = 1080
FPS = 60
SIDE_HOLD_FRAMES = 60
MOVE_FRAMES = 60
FRONT_HOLD_FRAMES = 72


def smoothstep(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def load_frame(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGB").resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)


def crop_motion(image: Image.Image, zoom: float, offset_x: float) -> Image.Image:
    scaled_width = int(round(WIDTH * zoom))
    scaled_height = int(round(HEIGHT * zoom))
    scaled = image.resize((scaled_width, scaled_height), Image.Resampling.LANCZOS)

    max_left = scaled_width - WIDTH
    left = int(round(max_left / 2 + offset_x))
    left = max(0, min(max_left, left))
    top = max(0, (scaled_height - HEIGHT) // 2)
    return scaled.crop((left, top, left + WIDTH, top + HEIGHT))


def horizontal_motion_trail(frame: Image.Image, strength: float) -> Image.Image:
    """Create directional blur without adding a third-party image dependency."""
    if strength <= 0.01:
        return frame

    source = np.asarray(frame, dtype=np.float32)
    radius = max(1, int(round(38 * strength)))
    offsets = np.linspace(-radius, radius, 9).round().astype(int)
    weights = np.array([1, 2, 3, 5, 7, 5, 3, 2, 1], dtype=np.float32)
    weights /= weights.sum()

    accumulated = np.zeros_like(source)
    for offset, weight in zip(offsets, weights, strict=True):
        shifted = np.roll(source, offset, axis=1)
        if offset > 0:
            shifted[:, :offset] = source[:, :1]
        elif offset < 0:
            shifted[:, offset:] = source[:, -1:]
        accumulated += shifted * weight

    return Image.fromarray(np.clip(accumulated, 0, 255).astype(np.uint8), "RGB")


def render_move_frame(side: Image.Image, front: Image.Image, progress: float) -> Image.Image:
    eased = smoothstep(progress)

    # Move toward the front end of the side view, then settle from a slightly
    # off-centre, closer front view.  There is deliberately no vertical bob.
    side_view = crop_motion(side, 1.0 + 0.105 * eased, -150.0 * eased)
    front_view = crop_motion(front, 1.105 - 0.105 * eased, 155.0 * (1.0 - eased))

    # Concentrate the actual viewpoint replacement around the fastest part of
    # the turn so both scan endpoints stay crisp and stable.
    blend = smoothstep((progress - 0.29) / 0.42)
    composed = Image.blend(side_view, front_view, blend)

    speed = math.sin(math.pi * progress)
    return horizontal_motion_trail(composed, speed)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    side = load_frame(SIDE_PATH)
    front = load_frame(FRONT_PATH)

    command = [
        "ffmpeg",
        "-y",
        "-f",
        "rawvideo",
        "-pix_fmt",
        "rgb24",
        "-s:v",
        f"{WIDTH}x{HEIGHT}",
        "-r",
        str(FPS),
        "-i",
        "-",
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "17",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(OUTPUT_PATH),
    ]

    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None

    try:
        side_bytes = side.tobytes()
        for _ in range(SIDE_HOLD_FRAMES):
            process.stdin.write(side_bytes)

        for index in range(MOVE_FRAMES):
            progress = index / (MOVE_FRAMES - 1)
            process.stdin.write(render_move_frame(side, front, progress).tobytes())

        front_bytes = front.tobytes()
        for _ in range(FRONT_HOLD_FRAMES):
            process.stdin.write(front_bytes)
    finally:
        process.stdin.close()

    exit_code = process.wait()
    if exit_code != 0:
        raise SystemExit(exit_code)

    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
