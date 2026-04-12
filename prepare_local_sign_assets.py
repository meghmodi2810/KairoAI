"""
Copy local sign images into Flutter assets using canonical structure:
  assets/signs/{LABEL}/image.{ext}

Default behavior also optimizes copied images in-place to reduce app size.

Usage:
  python prepare_local_sign_assets.py "D:\\Downloads\\all the images - 2"
"""

from pathlib import Path
import shutil
import sys

from PIL import Image

SOURCE_DEFAULT = Path(r"D:\Downloads\all the images - 2")
DEST_ROOT = Path(__file__).parent / "assets" / "signs"
SUPPORTED = {".png", ".jpg", ".jpeg", ".webp", ".gif"}


def normalize_label(name: str) -> str:
    return name.strip().upper()


def optimize_image(path: Path, max_size: int = 960, quality: int = 82) -> None:
    with Image.open(path) as img:
        img = img.convert("RGB")

        longest = max(img.width, img.height)
        if longest > max_size:
            scale = max_size / float(longest)
            new_size = (max(1, int(img.width * scale)), max(1, int(img.height * scale)))
            img = img.resize(new_size, Image.Resampling.LANCZOS)

        ext = path.suffix.lower()
        if ext == ".png":
            pal = img.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
            pal.save(path, format="PNG", optimize=True)
        elif ext in {".jpg", ".jpeg"}:
            img.save(path, format="JPEG", optimize=True, quality=quality)
        elif ext == ".webp":
            img.save(path, format="WEBP", quality=quality, method=6)
        elif ext == ".gif":
            img.save(path, format="GIF", optimize=True)


def main() -> int:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else SOURCE_DEFAULT
    if not source.exists() or not source.is_dir():
        print(f"Source folder not found: {source}")
        return 1

    copied = 0

    # Mode 1: nested dataset folders (e.g. E:/ISL_Model_Training/Indian/A/*.jpg)
    subdirs = [p for p in source.iterdir() if p.is_dir()]
    if subdirs:
        for subdir in sorted(subdirs, key=lambda p: p.name.lower()):
            label = normalize_label(subdir.name)
            if not label:
                continue

            candidates = [
                p for p in subdir.iterdir()
                if p.is_file() and p.suffix.lower() in SUPPORTED
            ]
            if not candidates:
                continue

            # Prefer numerically-small file names such as 0.jpg, 1.jpg.
            def _sort_key(path: Path) -> tuple[int, str]:
                stem = path.stem.strip()
                if stem.isdigit():
                    return (0, f"{int(stem):08d}")
                return (1, stem.lower())

            candidates.sort(key=_sort_key)
            chosen = candidates[0]

            dest_dir = DEST_ROOT / label
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest_file = dest_dir / f"image{chosen.suffix.lower()}"
            shutil.copy2(chosen, dest_file)
            optimize_image(dest_file)
            copied += 1
            print(f"{subdir.name}/{chosen.name} -> {dest_file}")

    # Mode 2: flat folder of files (legacy behavior).
    else:
        files = [
            p for p in source.iterdir() if p.is_file() and p.suffix.lower() in SUPPORTED
        ]
        files.sort(key=lambda p: p.name.lower())

        if not files:
            print("No supported image files found.")
            return 1

        for file_path in files:
            label = normalize_label(file_path.stem)
            dest_dir = DEST_ROOT / label
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest_file = dest_dir / f"image{file_path.suffix.lower()}"
            shutil.copy2(file_path, dest_file)
            optimize_image(dest_file)
            copied += 1
            print(f"{file_path.name} -> {dest_file}")

    if copied == 0:
        print("No supported image files found.")
        return 1

    print(f"Copied {copied} file(s) to {DEST_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
