"""
Optimize bundled sign images in-place to reduce Flutter app size.

Default behavior:
- Scans assets/signs/**/image.*
- Resizes images to max 960px on the longest side (if larger)
- Converts to RGB palette PNG (256 colors) and saves optimized
- Keeps existing file names and paths unchanged

Usage:
  e:/KairoAI/.venv/Scripts/python.exe optimize_sign_assets.py
  e:/KairoAI/.venv/Scripts/python.exe optimize_sign_assets.py --max-size 768 --quality 80
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image


SUPPORTED = {".png", ".jpg", ".jpeg", ".webp"}
ASSET_ROOT = Path(__file__).parent / "assets" / "signs"


@dataclass
class FileStat:
    path: Path
    before: int
    after: int


def iter_image_files(root: Path) -> Iterable[Path]:
    if not root.exists():
        return []
    return sorted(
        [p for p in root.rglob("image.*") if p.is_file() and p.suffix.lower() in SUPPORTED]
    )


def optimize_file(path: Path, max_size: int, quality: int) -> FileStat:
    before = path.stat().st_size

    with Image.open(path) as img:
        img = img.convert("RGB")

        # Resize only when needed, preserving aspect ratio.
        longest = max(img.width, img.height)
        if longest > max_size:
            scale = max_size / float(longest)
            new_size = (max(1, int(img.width * scale)), max(1, int(img.height * scale)))
            img = img.resize(new_size, Image.Resampling.LANCZOS)

        # Keep original extension so existing asset paths remain valid.
        ext = path.suffix.lower()
        if ext == ".png":
            pal = img.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
            pal.save(path, format="PNG", optimize=True)
        elif ext in {".jpg", ".jpeg"}:
            img.save(path, format="JPEG", optimize=True, quality=quality)
        elif ext == ".webp":
            img.save(path, format="WEBP", quality=quality, method=6)

    after = path.stat().st_size
    return FileStat(path=path, before=before, after=after)


def fmt_size(num_bytes: int) -> str:
    mb = num_bytes / (1024 * 1024)
    return f"{mb:.2f} MB"


def main() -> int:
    parser = argparse.ArgumentParser(description="Optimize local sign assets in-place")
    parser.add_argument("--max-size", type=int, default=960, help="Longest image side after resize")
    parser.add_argument("--quality", type=int, default=82, help="JPEG/WEBP quality")
    args = parser.parse_args()

    files = list(iter_image_files(ASSET_ROOT))
    if not files:
        print(f"No supported image files found under: {ASSET_ROOT}")
        return 1

    stats: list[FileStat] = []
    for file_path in files:
        stat = optimize_file(file_path, max_size=args.max_size, quality=args.quality)
        stats.append(stat)

    total_before = sum(s.before for s in stats)
    total_after = sum(s.after for s in stats)
    saved = total_before - total_after
    pct = (saved / total_before * 100.0) if total_before else 0.0

    print(f"Processed: {len(stats)} file(s)")
    print(f"Before: {fmt_size(total_before)}")
    print(f"After:  {fmt_size(total_after)}")
    print(f"Saved:  {fmt_size(saved)} ({pct:.1f}%)")

    # Print top 5 biggest savings for quick visibility.
    top = sorted(stats, key=lambda s: (s.before - s.after), reverse=True)[:5]
    print("Top savings:")
    for s in top:
        delta = s.before - s.after
        print(f"- {s.path.as_posix()}: {fmt_size(delta)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
