"""Render a real multi-keyframe side-to-front walking test.

Unlike the two-photo transition test, this renderer uses five generated
intermediate viewpoints. FFmpeg motion-compensated interpolation creates the
in-between frames while the scan holds remain completely static.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
MOBILE_FRAMES = ROOT / "prototype" / "mobile" / "assets" / "frames"
KEYFRAMES = ROOT / "prototype" / "video-demo" / "assets" / "still-walk-keyframes"
OUTPUT = (
    ROOT
    / "prototype"
    / "video-demo"
    / "output"
    / "rife-multikeyframe-walk-side-to-front-test.mp4"
)

WORK_WIDTH = 960
WORK_HEIGHT = 540
OUTPUT_WIDTH = 1920
OUTPUT_HEIGHT = 1080
SOURCE_FPS = 5
OUTPUT_FPS = 60
RIFE_FRAME_COUNT = 193


def find_rife() -> Path:
    configured = os.environ.get("IRENT_RIFE_PATH")
    if configured:
        candidate = Path(configured)
    else:
        candidate = (
            Path.home()
            / ".codex"
            / "tools"
            / "rife-ncnn-vulkan-20221029"
            / "rife-ncnn-vulkan-20221029-windows"
            / "rife-ncnn-vulkan.exe"
        )
    if not candidate.is_file():
        raise FileNotFoundError(
            "rife-ncnn-vulkan.exe not found. Set IRENT_RIFE_PATH to its full path."
        )
    return candidate


def load(path: Path) -> bytes:
    with Image.open(path) as image:
        frame = image.convert("RGB").resize(
            (WORK_WIDTH, WORK_HEIGHT), Image.Resampling.LANCZOS
        )
    return frame.tobytes()


def main() -> None:
    side = load(MOBILE_FRAMES / "exterior_clean_source.png")
    front = load(MOBILE_FRAMES / "vehicle_front.png")
    movement = [
        load(KEYFRAMES / "angle-15.png"),
        load(KEYFRAMES / "angle-30.png"),
        load(KEYFRAMES / "angle-45.png"),
        load(KEYFRAMES / "angle-60.png"),
        load(KEYFRAMES / "angle-75.png"),
    ]

    # One second of perfectly stable side scanning, a 1.2-second seven-angle
    # walk, then a stable front scan. Repeated endpoint frames make the stops
    # deterministic and keep UI synchronization straightforward.
    frames = [side] * 5 + movement + [front] * 7

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    rife = find_rife()
    model = rife.parent / "rife-v4.6"

    with tempfile.TemporaryDirectory(prefix="irent-rife-") as temp_name:
        temp = Path(temp_name)
        input_dir = temp / "input"
        output_dir = temp / "output"
        input_dir.mkdir()
        output_dir.mkdir()

        for index, frame in enumerate(frames):
            image = Image.frombytes("RGB", (WORK_WIDTH, WORK_HEIGHT), frame)
            image.save(input_dir / f"{index:08d}.png")

        subprocess.run(
            [
                str(rife),
                "-i",
                str(input_dir),
                "-o",
                str(output_dir),
                "-n",
                str(RIFE_FRAME_COUNT),
                "-m",
                str(model),
                "-g",
                "0",
                "-j",
                "2:2:2",
                "-f",
                "%08d.png",
            ],
            check=True,
            cwd=rife.parent,
        )

        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-framerate",
                str(OUTPUT_FPS),
                "-i",
                str(output_dir / "%08d.png"),
                "-an",
                "-vf",
                (
                    "tpad=stop_mode=clone:stop_duration=0.2,"
                    f"scale={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}:flags=lanczos"
                ),
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
                str(OUTPUT),
            ],
            check=True,
        )

    print(OUTPUT)


if __name__ == "__main__":
    main()
