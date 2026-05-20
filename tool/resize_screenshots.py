#!/usr/bin/env python3
"""iPhone 6.7-inch 撮影スクショから iPhone 6.5-inch (1242x2688) を生成。

ASC は新規アプリで 6.7 inch (1290x2796) と 6.5 inch (1242x2688) の
両方のスクショセット提出を要求するケースがある。
撮影済みの 6.7 を Lanczos リサイズしてフォルダ差で fastlane が
別 target として認識する。

iPad は 2048x2732 でそのまま 12.9-inch (3rd Gen) target として扱われる。
"""

import os
from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).parent.parent
JA_DIR = PROJECT / "ios" / "fastlane" / "screenshots" / "ja"
EN_DIR = PROJECT / "ios" / "fastlane" / "screenshots" / "en-US"


def resize_for_target(src_dir: Path, dst_dir: Path, w: int, h: int):
    if not src_dir.exists():
        print(f"  SKIP: {src_dir} not found")
        return 0
    dst_dir.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted(src_dir.iterdir()):
        if f.suffix.lower() != ".png":
            continue
        img = Image.open(f)
        if img.size == (w, h):
            # 同サイズなら copy のみ
            img.save(dst_dir / f.name)
        else:
            img.resize((w, h), Image.LANCZOS).save(dst_dir / f.name, optimize=True)
        print(f"  {f.name}: {img.size} -> ({w}x{h})")
        n += 1
    return n


def show_existing(d: Path):
    if not d.exists():
        return
    print(f"-- {d.relative_to(PROJECT)} --")
    for f in sorted(d.iterdir()):
        if f.suffix.lower() != ".png":
            continue
        with Image.open(f) as img:
            print(f"  {f.name}: {img.size}")


def main():
    print("== existing ==")
    for sub in ["iPhone 6.7-inch", "iPhone 6.5-inch", "iPad Pro 12.9-inch"]:
        show_existing(JA_DIR / sub)

    print()
    print("== ja: iPhone 6.5 inch resize ==")
    resize_for_target(
        JA_DIR / "iPhone 6.7-inch",
        JA_DIR / "iPhone 6.5-inch",
        1242,
        2688,
    )

    if EN_DIR.exists():
        print()
        print("== en-US: iPhone 6.5 inch resize ==")
        resize_for_target(
            EN_DIR / "iPhone 6.7-inch",
            EN_DIR / "iPhone 6.5-inch",
            1242,
            2688,
        )


if __name__ == "__main__":
    main()
