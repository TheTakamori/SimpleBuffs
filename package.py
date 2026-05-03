#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent
ADDON_NAME = "SimpleBuffs"
VERSION = "0.1.0"
OUTPUT = ROOT / f"{ADDON_NAME}-{VERSION}.zip"
EXCLUDED_DIRS = {".git", "__pycache__", "build", "dist", "release", "tests"}
EXCLUDED_FILES = {".gitignore", "CURSEFORGE_SUBMISSION.md", "package.py"}


def should_package(path: Path) -> bool:
    relative = path.relative_to(ROOT)
    if any(part in EXCLUDED_DIRS for part in relative.parts):
        return False
    if path.name in EXCLUDED_FILES or path.suffix == ".zip":
        return False
    return path.is_file()


with ZipFile(OUTPUT, "w", ZIP_DEFLATED) as archive:
    for path in sorted(ROOT.rglob("*")):
        if should_package(path):
            archive.write(path, Path(ADDON_NAME) / path.relative_to(ROOT))

print(f"Wrote {OUTPUT.name}")
