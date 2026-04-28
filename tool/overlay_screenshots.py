#!/usr/bin/env python3
"""App Store screenshots: marketing text overlay + resize

Input:  screenshots/raw/raw_*.png, screenshots/ipad/ipad_*.png
Output: ios/fastlane/screenshots/ja/iPhone 6.7-inch/*.png
        ios/fastlane/screenshots/ja/iPad Pro 12.9-inch/*.png
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PROJECT = Path(__file__).parent.parent
RAW_DIR = PROJECT / "screenshots" / "raw"
IPAD_DIR = PROJECT / "screenshots" / "ipad"
IPHONE_OUT = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPhone 6.7-inch"
IPAD_OUT = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPad Pro 12.9-inch"

IPHONE_OUT.mkdir(parents=True, exist_ok=True)
IPAD_OUT.mkdir(parents=True, exist_ok=True)

# --- Fonts ---
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"
FONT_REGULAR = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

# --- iPhone 6.7-inch (1290x2796) ---
IP_W, IP_H = 1290, 2796
IP_TEXT_H = 520
IP_PAD = 40
IP_CORNER = 30
IP_TITLE_SZ = 82
IP_SUB_SZ = 46
IP_TITLE_Y = 160
IP_SUB_Y = 290

# --- iPad 12.9-inch (2048x2732) ---
PD_W, PD_H = 2048, 2732
PD_TEXT_H = 700
PD_PAD = 60
PD_CORNER = 40
PD_TITLE_SZ = 120
PD_SUB_SZ = 68
PD_TITLE_Y = 210
PD_SUB_Y = 390

CONFIGS = [
    {
        "raw": "raw_01_home.png",
        "ipad": "ipad_01_home.png",
        "out": "01_home.png",
        "line1": "やることが多すぎる？",
        "line2": "AIが全部整理してくれる。",
        "bg_top": (220, 230, 255),
        "bg_btm": (180, 200, 255),
        "color": (30, 40, 120),
    },
    {
        "raw": "raw_02_ai_result.png",
        "ipad": "ipad_02_ai_result.png",
        "out": "02_ai_result.png",
        "line1": "AIが優先順位を判断",
        "line2": "具体的なアドバイス付き",
        "bg_top": (240, 220, 255),
        "bg_btm": (210, 180, 255),
        "color": (60, 20, 120),
    },
    {
        "raw": "raw_03_calendar.png",
        "ipad": "ipad_03_calendar.png",
        "out": "03_calendar.png",
        "line1": "いつやるかが一目でわかる",
        "line2": "",
        "bg_top": (220, 255, 230),
        "bg_btm": (180, 240, 200),
        "color": (20, 80, 40),
    },
    {
        "raw": "raw_04_ai_comment.png",
        "ipad": "ipad_04_ai_comment.png",
        "out": "04_notification.png",
        "line1": "通知で忘れない",
        "line2": "やるべき日にだけお知らせ",
        "bg_top": (255, 235, 220),
        "bg_btm": (255, 210, 180),
        "color": (120, 50, 10),
    },
    {
        "raw": "raw_05_simple_input.png",
        "ipad": "ipad_05_simple_input.png",
        "out": "05_simple_input.png",
        "line1": "入力はたった2つだけ",
        "line2": "タスク名と期限を入れるだけ",
        "bg_top": (255, 225, 235),
        "bg_btm": (255, 200, 220),
        "color": (120, 20, 60),
    },
]


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *size], radius=radius, fill=255)
    return mask


def draw_circles(img, bg_top, bg_btm, text_h):
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    specs = [
        (0.15, 0.30, 140, bg_btm, 35),
        (0.82, 0.15, 100, bg_top, 30),
        (0.50, 0.60, 80, (255, 255, 255), 40),
    ]
    for xr, yr, r, c, a in specs:
        r_scaled = int(r * img.width / 1290)
        x, y = int(img.width * xr), int(text_h * yr)
        d.ellipse([x - r_scaled, y - r_scaled, x + r_scaled, y + r_scaled],
                  fill=(*c, a))
    ov = ov.filter(ImageFilter.GaussianBlur(radius=int(80 * img.width / 1290)))
    img.paste(
        Image.alpha_composite(Image.new("RGBA", img.size, (0, 0, 0, 0)), ov),
        (0, 0), ov,
    )


def process(cfg, raw_dir, out_dir, w, h, text_h, pad, corner,
            title_sz, sub_sz, title_y, sub_y):
    raw_key = "ipad" if raw_dir == IPAD_DIR else "raw"
    raw_name = cfg.get(raw_key, cfg["raw"])
    raw_path = raw_dir / raw_name
    if not raw_path.exists():
        print(f"  SKIP: {raw_name} not found")
        return

    bg_top, bg_btm, color = cfg["bg_top"], cfg["bg_btm"], cfg["color"]

    # Gradient background
    final = Image.new("RGBA", (w, h))
    draw = ImageDraw.Draw(final)
    for y_pos in range(h):
        t = y_pos / h
        draw.line(
            [(0, y_pos), (w, y_pos)],
            fill=(
                int(bg_top[0] + (bg_btm[0] - bg_top[0]) * t),
                int(bg_top[1] + (bg_btm[1] - bg_top[1]) * t),
                int(bg_top[2] + (bg_btm[2] - bg_top[2]) * t),
                255,
            ),
        )

    draw_circles(final, bg_top, bg_btm, text_h)

    # Text
    draw = ImageDraw.Draw(final)
    ft = ImageFont.truetype(FONT_BOLD, title_sz)
    fs = ImageFont.truetype(FONT_REGULAR, sub_sz)

    bb1 = draw.textbbox((0, 0), cfg["line1"], font=ft)
    draw.text(((w - bb1[2] + bb1[0]) // 2, title_y),
              cfg["line1"], fill=color, font=ft)

    if cfg["line2"]:
        bb2 = draw.textbbox((0, 0), cfg["line2"], font=fs)
        draw.text(((w - bb2[2] + bb2[0]) // 2, sub_y),
                  cfg["line2"], fill=(*color, 200), font=fs)

    # Screenshot overlay
    raw = Image.open(raw_path).convert("RGBA")
    ss_w = w - pad * 2
    ss_h = h - text_h - pad
    raw_ratio = raw.width / raw.height
    target_ratio = ss_w / ss_h
    if raw_ratio > target_ratio:
        new_w = ss_w
        new_h = int(ss_w / raw_ratio)
    else:
        new_h = ss_h
        new_w = int(ss_h * raw_ratio)
    raw = raw.resize((new_w, new_h), Image.LANCZOS)

    mask = rounded_mask(raw.size, corner)
    rounded = Image.new("RGBA", raw.size, (0, 0, 0, 0))
    rounded.paste(raw, (0, 0), mask)

    px = (w - new_w) // 2
    py = text_h
    final.paste(rounded, (px, py), rounded)

    out_path = out_dir / cfg["out"]
    final.convert("RGB").save(out_path, "PNG")
    kb = out_path.stat().st_size / 1024
    print(f"  {cfg['out']} ({w}x{h}, {kb:.0f}KB)")


def main():
    print("=== iPhone 6.7-inch (1290x2796) ===")
    for c in CONFIGS:
        process(c, RAW_DIR, IPHONE_OUT, IP_W, IP_H, IP_TEXT_H, IP_PAD,
                IP_CORNER, IP_TITLE_SZ, IP_SUB_SZ, IP_TITLE_Y, IP_SUB_Y)

    # IAP review
    iap_src = RAW_DIR / "raw_iap.png"
    iap_dst = IPHONE_OUT / "iap_review.png"
    if iap_src.exists():
        img = Image.open(iap_src).resize((IP_W, IP_H), Image.LANCZOS)
        img.save(iap_dst, "PNG")
        kb = iap_dst.stat().st_size / 1024
        print(f"  iap_review.png ({IP_W}x{IP_H}, {kb:.0f}KB)")

    print("\n=== iPad Pro 12.9-inch (2048x2732) ===")
    for c in CONFIGS:
        process(c, IPAD_DIR, IPAD_OUT, PD_W, PD_H, PD_TEXT_H, PD_PAD,
                PD_CORNER, PD_TITLE_SZ, PD_SUB_SZ, PD_TITLE_Y, PD_SUB_Y)

    # iPad IAP
    iap_src = IPAD_DIR / "ipad_iap.png"
    iap_dst = IPAD_OUT / "iap_review.png"
    if iap_src.exists():
        img = Image.open(iap_src).resize((PD_W, PD_H), Image.LANCZOS)
        img.save(iap_dst, "PNG")
        kb = iap_dst.stat().st_size / 1024
        print(f"  iap_review.png ({PD_W}x{PD_H}, {kb:.0f}KB)")

    print("\nDone.")
    print(f"iPhone: {IPHONE_OUT}")
    print(f"iPad:   {IPAD_OUT}")


if __name__ == "__main__":
    main()
