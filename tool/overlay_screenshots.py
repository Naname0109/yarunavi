#!/usr/bin/env python3
"""App Store スクリーンショットにマーケティングテキストをオーバーレイする

使い方:
  python3 tool/overlay_screenshots.py

入力: screenshots/raw/raw_*.png, screenshots/ipad/ipad_*.png
出力: ios/fastlane/screenshots/ja/iPhone 6.5-inch/*.png
      ios/fastlane/screenshots/ja/iPad Pro 12.9-inch/*.png
"""

import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# --- パス設定 ---
PROJECT = Path(__file__).parent.parent
RAW_DIR = PROJECT / "screenshots" / "raw"
IPAD_DIR = PROJECT / "screenshots" / "ipad"
IPHONE_OUT = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPhone 6.5-inch"
IPAD_OUT = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPad Pro 12.9-inch"

IPHONE_OUT.mkdir(parents=True, exist_ok=True)
IPAD_OUT.mkdir(parents=True, exist_ok=True)

# --- 画像設定 ---
FINAL_W, FINAL_H = 1284, 2778
TEXT_AREA_H = 500
PAD = 40
CORNER_RADIUS = 30

# --- フォント ---
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"
FONT_REGULAR = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
TITLE_SIZE = 80
SUB_SIZE = 44
TITLE_Y = 160
SUB_Y = 280

# --- 各画像の設定 ---
CONFIGS = [
    {
        "raw": "raw_01_home.png",
        "out": "01_home.png",
        "line1": "やることを入れるだけ。",
        "line2": "AIが整理してくれる。",
        "bg_top": (220, 230, 255),
        "bg_btm": (180, 200, 255),
        "color": (30, 40, 120),
    },
    {
        "raw": "raw_02_ai_result.png",
        "out": "02_ai_result.png",
        "line1": "AIが優先順位を判断",
        "line2": "具体的なアドバイス付き",
        "bg_top": (240, 220, 255),
        "bg_btm": (210, 180, 255),
        "color": (60, 20, 120),
    },
    {
        "raw": "raw_03_calendar.png",
        "out": "03_calendar.png",
        "line1": "いつやるかが",
        "line2": "一目でわかる",
        "bg_top": (220, 255, 230),
        "bg_btm": (180, 240, 200),
        "color": (20, 80, 40),
    },
    {
        "raw": "raw_04_ai_comment.png",
        "out": "04_ai_comment.png",
        "line1": "AIが具体的にアドバイス",
        "line2": "タスクごとに最適な行動を提案",
        "bg_top": (255, 235, 220),
        "bg_btm": (255, 210, 180),
        "color": (120, 50, 10),
    },
    {
        "raw": "raw_05_onboarding.png",
        "out": "05_notification.png",
        "line1": "やるべき日に通知。",
        "line2": "忘れない。",
        "bg_top": (255, 225, 235),
        "bg_btm": (255, 200, 220),
        "color": (120, 20, 60),
    },
]


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *size], radius=radius, fill=255)
    return mask


def draw_circles(img, bg_top, bg_btm):
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    circles = [
        (0.15, 0.30, 140, bg_btm, 35),
        (0.82, 0.15, 100, bg_top, 30),
        (0.50, 0.60, 80, (255, 255, 255), 40),
    ]
    for xr, yr, r, c, a in circles:
        x, y = int(img.width * xr), int(TEXT_AREA_H * yr)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(*c, a))
    ov = ov.filter(ImageFilter.GaussianBlur(radius=80))
    img.paste(Image.alpha_composite(Image.new("RGBA", img.size, (0, 0, 0, 0)), ov), (0, 0), ov)


def process(cfg):
    raw_path = RAW_DIR / cfg["raw"]
    if not raw_path.exists():
        print(f"  SKIP: {cfg['raw']} not found")
        return

    bg_top, bg_btm, color = cfg["bg_top"], cfg["bg_btm"], cfg["color"]

    # グラデーション背景
    final = Image.new("RGBA", (FINAL_W, FINAL_H))
    draw = ImageDraw.Draw(final)
    for y in range(FINAL_H):
        r = y / FINAL_H
        draw.line(
            [(0, y), (FINAL_W, y)],
            fill=(
                int(bg_top[0] + (bg_btm[0] - bg_top[0]) * r),
                int(bg_top[1] + (bg_btm[1] - bg_top[1]) * r),
                int(bg_top[2] + (bg_btm[2] - bg_top[2]) * r),
                255,
            ),
        )

    # ぼかし円装飾
    draw_circles(final, bg_top, bg_btm)

    # テキスト描画
    draw = ImageDraw.Draw(final)
    ft = ImageFont.truetype(FONT_BOLD, TITLE_SIZE)
    fs = ImageFont.truetype(FONT_REGULAR, SUB_SIZE)

    bb1 = draw.textbbox((0, 0), cfg["line1"], font=ft)
    draw.text(((FINAL_W - bb1[2] + bb1[0]) // 2, TITLE_Y), cfg["line1"], fill=color, font=ft)

    bb2 = draw.textbbox((0, 0), cfg["line2"], font=fs)
    draw.text(((FINAL_W - bb2[2] + bb2[0]) // 2, SUB_Y), cfg["line2"], fill=(*color, 200), font=fs)

    # rawスクショ読み込み・リサイズ・角丸
    raw = Image.open(raw_path).convert("RGBA")
    ss_w = FINAL_W - PAD * 2
    ss_h = FINAL_H - TEXT_AREA_H - PAD
    # アスペクト比を維持してリサイズ
    raw_ratio = raw.width / raw.height
    target_ratio = ss_w / ss_h
    if raw_ratio > target_ratio:
        new_w = ss_w
        new_h = int(ss_w / raw_ratio)
    else:
        new_h = ss_h
        new_w = int(ss_h * raw_ratio)
    raw = raw.resize((new_w, new_h), Image.LANCZOS)

    mask = rounded_mask(raw.size, CORNER_RADIUS)
    rounded = Image.new("RGBA", raw.size, (0, 0, 0, 0))
    rounded.paste(raw, (0, 0), mask)

    # 配置（中央寄せ）
    px = (FINAL_W - new_w) // 2
    py = TEXT_AREA_H
    final.paste(rounded, (px, py), rounded)

    # 保存
    out_path = IPHONE_OUT / cfg["out"]
    final.convert("RGB").save(out_path, "PNG")
    kb = out_path.stat().st_size / 1024
    print(f"  ✅ {cfg['out']} ({FINAL_W}x{FINAL_H}, {kb:.0f}KB)")


def main():
    print("=== iPhone マーケティングオーバーレイ加工 ===")
    for c in CONFIGS:
        process(c)

    # IAP: リサイズのみ
    iap_src = RAW_DIR / "raw_iap.png"
    iap_dst = IPHONE_OUT / "iap_review.png"
    if iap_src.exists():
        img = Image.open(iap_src)
        img = img.resize((FINAL_W, FINAL_H), Image.LANCZOS)
        img.save(iap_dst, "PNG")
        kb = iap_dst.stat().st_size / 1024
        print(f"  ✅ iap_review.png ({FINAL_W}x{FINAL_H}, {kb:.0f}KB)")

    # iPad: そのままコピー
    print("\n=== iPad スクリーンショットコピー ===")
    ipad_files = [
        "ipad_01_home.png",
        "ipad_02_ai_result.png",
        "ipad_03_calendar.png",
        "ipad_04_ai_comment.png",
        "ipad_05_store.png",
    ]
    for f in ipad_files:
        src = IPAD_DIR / f
        dst = IPAD_OUT / f
        if src.exists():
            shutil.copy2(src, dst)
            img = Image.open(dst)
            kb = dst.stat().st_size / 1024
            print(f"  ✅ {f} ({img.size[0]}x{img.size[1]}, {kb:.0f}KB)")
        else:
            print(f"  SKIP: {f} not found")

    print("\n=== 完了 ===")
    print(f"iPhone: {IPHONE_OUT}")
    print(f"iPad:   {IPAD_OUT}")


if __name__ == "__main__":
    main()
