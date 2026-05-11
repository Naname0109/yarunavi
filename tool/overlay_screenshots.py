#!/usr/bin/env python3
"""App Store screenshots: marketing text overlay + resize (v2 - enhanced design)

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
ICON_PATH = PROJECT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-App-1024x1024@1x.png"

IPHONE_OUT.mkdir(parents=True, exist_ok=True)
IPAD_OUT.mkdir(parents=True, exist_ok=True)

# --- Fonts ---
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"

# --- iPhone 6.7-inch (1290x2796) ---
IP_W, IP_H = 1290, 2796
IP_TEXT_H = 560
IP_PAD = 50
IP_CORNER = 40
IP_TITLE_SZ = 96

# --- iPad 12.9-inch (2048x2732) ---
PD_W, PD_H = 2048, 2732
PD_TEXT_H = 720
PD_PAD = 70
PD_CORNER = 50
PD_TITLE_SZ = 130

# Each config has line1 and line2, each with segments: [(text, is_highlight), ...]
CONFIGS = [
    {
        "raw": "raw_01_home.png",
        "ipad": "ipad_01_home.png",
        "out": "01_home.png",
        "line1": [("もう何からやろうと", False)],
        "line2": [("悩まない", True)],
        "bg_colors": [(30, 60, 160), (20, 30, 100)],
        "text_color": (255, 255, 255),
        "highlight_color": (100, 200, 255),
        "circles": [(0.15, 0.35, 180, (60, 120, 255), 50),
                    (0.85, 0.20, 130, (100, 160, 255), 40),
                    (0.50, 0.70, 100, (40, 80, 200), 35),
                    (0.25, 0.80, 90, (80, 140, 240), 30),
                    (0.75, 0.55, 110, (50, 100, 220), 45)],
        "rotate": 0,
        "show_badge": True,
    },
    {
        "raw": "raw_02_ai_result.png",
        "ipad": "ipad_02_ai_result.png",
        "out": "02_ai_result.png",
        "line1": [("今日やるべきこと", False)],
        "line2": [("AI", True), ("が教えてくれる", False)],
        "bg_colors": [(100, 30, 140), (60, 10, 90)],
        "text_color": (255, 255, 255),
        "highlight_color": (220, 140, 255),
        "circles": [(0.20, 0.30, 160, (140, 60, 200), 45),
                    (0.80, 0.25, 120, (180, 100, 240), 35),
                    (0.55, 0.65, 140, (100, 40, 160), 40),
                    (0.10, 0.75, 100, (160, 80, 220), 30),
                    (0.90, 0.60, 90, (120, 50, 180), 35)],
        "rotate": 3,
        "show_badge": False,
    },
    {
        "raw": "raw_03_calendar.png",
        "ipad": "ipad_03_calendar.png",
        "out": "03_calendar.png",
        "line1": [("カレンダーで", False)],
        "line2": [("一目瞭然", True)],
        "bg_colors": [(10, 100, 80), (5, 60, 50)],
        "text_color": (255, 255, 255),
        "highlight_color": (80, 240, 200),
        "circles": [(0.20, 0.35, 150, (20, 160, 120), 45),
                    (0.80, 0.20, 120, (40, 180, 140), 35),
                    (0.45, 0.70, 130, (15, 120, 90), 40),
                    (0.70, 0.55, 90, (30, 140, 110), 30),
                    (0.10, 0.60, 100, (25, 150, 110), 35)],
        "rotate": -3,
        "show_badge": False,
    },
    {
        "raw": "raw_04_ai_comment.png",
        "ipad": "ipad_04_ai_comment.png",
        "out": "04_notification.png",
        "line1": [("うっかり忘れを", False)],
        "line2": [("ゼロ", True), ("に", False)],
        "bg_colors": [(160, 60, 10), (100, 30, 5)],
        "text_color": (255, 255, 255),
        "highlight_color": (255, 180, 80),
        "circles": [(0.15, 0.30, 160, (200, 80, 20), 45),
                    (0.85, 0.25, 130, (220, 100, 30), 40),
                    (0.50, 0.65, 110, (180, 60, 15), 35),
                    (0.30, 0.75, 90, (240, 120, 40), 30),
                    (0.75, 0.50, 100, (190, 70, 20), 35)],
        "rotate": 3,
        "show_badge": False,
    },
    {
        "raw": "raw_05_simple_input.png",
        "ipad": "ipad_05_simple_input.png",
        "out": "05_simple_input.png",
        "line1": [("2秒", True), ("で登録", False)],
        "line2": [("あとはAIにおまかせ", False)],
        "bg_colors": [(10, 80, 160), (5, 50, 120)],
        "text_color": (255, 255, 255),
        "highlight_color": (80, 200, 255),
        "circles": [(0.20, 0.30, 150, (20, 120, 200), 45),
                    (0.80, 0.20, 120, (40, 140, 220), 35),
                    (0.50, 0.65, 130, (15, 100, 180), 40),
                    (0.70, 0.50, 90, (30, 110, 190), 30),
                    (0.10, 0.70, 100, (25, 130, 210), 35)],
        "rotate": -4,
        "show_badge": False,
    },
]


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *size], radius=radius, fill=255)
    return mask


def draw_gradient(img, color_top, color_btm):
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        t = y / h
        r = int(color_top[0] + (color_btm[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_btm[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_btm[2] - color_top[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))


def draw_circles(img, circles, w, text_h):
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    scale = w / 1290
    for xr, yr, r, c, a in circles:
        r_scaled = int(r * scale)
        x = int(w * xr)
        y = int(text_h * yr)
        d.ellipse([x - r_scaled, y - r_scaled, x + r_scaled, y + r_scaled],
                  fill=(*c, a))
    ov = ov.filter(ImageFilter.GaussianBlur(radius=int(100 * scale)))
    img.paste(
        Image.alpha_composite(Image.new("RGBA", img.size, (0, 0, 0, 0)), ov),
        (0, 0), ov,
    )


def draw_dot_pattern(img, w, h, text_h):
    ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    spacing = int(40 * w / 1290)
    dot_r = int(2 * w / 1290)
    for x in range(0, w, spacing):
        for y in range(0, text_h, spacing):
            d.ellipse([x - dot_r, y - dot_r, x + dot_r, y + dot_r],
                      fill=(255, 255, 255, 12))
    img.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0, 0, 0, 0)), ov),
              (0, 0), ov)


def draw_segmented_line(draw, segments, cfg, w, y, font, shadow_offset):
    """Draw a line of text with mixed colors, centered."""
    full_text = "".join(s[0] for s in segments)
    bb_full = draw.textbbox((0, 0), full_text, font=font)
    total_w = bb_full[2] - bb_full[0]
    x = (w - total_w) // 2

    shadow_color = (0, 0, 0, 80)
    for text, is_highlight in segments:
        bb = draw.textbbox((0, 0), text, font=font)
        tw = bb[2] - bb[0]
        color = cfg["highlight_color"] if is_highlight else cfg["text_color"]
        draw.text((x + shadow_offset, y + shadow_offset), text,
                  fill=shadow_color, font=font)
        draw.text((x, y), text, fill=color, font=font)
        x += tw


def draw_text_lines(draw, cfg, w, title_sz, scale):
    """Draw line1 and line2, vertically centered in the text area."""
    ft = ImageFont.truetype(FONT_BOLD, title_sz)
    shadow_offset = int(3 * scale)

    line_spacing = int(20 * scale)
    line1_bb = draw.textbbox((0, 0), "".join(s[0] for s in cfg["line1"]), font=ft)
    line2_bb = draw.textbbox((0, 0), "".join(s[0] for s in cfg["line2"]), font=ft)
    line1_h = line1_bb[3] - line1_bb[1]
    line2_h = line2_bb[3] - line2_bb[1]
    total_text_h = line1_h + line_spacing + line2_h

    # Badge on 1st screenshot shifts text down a bit
    if cfg["show_badge"]:
        start_y = int(220 * scale)
    else:
        start_y = int(140 * scale) + (int(300 * scale) - total_text_h) // 2

    draw_segmented_line(draw, cfg["line1"], cfg, w, start_y, ft, shadow_offset)
    draw_segmented_line(draw, cfg["line2"], cfg, w, start_y + line1_h + line_spacing, ft, shadow_offset)


def add_shadow_to_screenshot(img, offset=15, blur=30):
    shadow = Image.new("RGBA", (img.width + offset * 4, img.height + offset * 4), (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    sd.rounded_rectangle(
        [offset * 2, offset * 2, offset * 2 + img.width, offset * 2 + img.height],
        radius=40, fill=(0, 0, 0, 100)
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=blur))
    shadow.paste(shadow_layer, (0, 0), shadow_layer)
    shadow.paste(img, (offset * 2, offset * 2), img)
    return shadow


def rotate_screenshot(img, angle):
    if angle == 0:
        return img
    return img.rotate(angle, resample=Image.BICUBIC, expand=True,
                      fillcolor=(0, 0, 0, 0))


def draw_badge(img, w, scale):
    icon_size = int(80 * scale)
    badge_h = int(36 * scale)
    badge_y = int(120 * scale)

    # Center icon + badge horizontally
    ft = ImageFont.truetype(FONT_BOLD, int(22 * scale))
    badge_text = "AI搭載"
    bb = ImageDraw.Draw(img).textbbox((0, 0), badge_text, font=ft)
    tw = bb[2] - bb[0]
    badge_w = tw + int(24 * scale)
    gap = int(16 * scale)
    total_badge_w = icon_size + gap + badge_w
    start_x = (w - total_badge_w) // 2

    # App icon
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA")
        icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
        icon_mask = rounded_mask((icon_size, icon_size), int(icon_size * 0.22))
        icon_rounded = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
        icon_rounded.paste(icon, (0, 0), icon_mask)
        img.paste(icon_rounded, (start_x, badge_y), icon_rounded)

    # "AI搭載" badge pill
    badge_x = start_x + icon_size + gap
    badge_y_center = badge_y + (icon_size - badge_h) // 2

    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    d.rounded_rectangle(
        [badge_x, badge_y_center, badge_x + badge_w, badge_y_center + badge_h],
        radius=int(badge_h // 2), fill=(100, 200, 255, 220)
    )
    img.paste(Image.alpha_composite(Image.new("RGBA", img.size, (0, 0, 0, 0)), ov),
              (0, 0), ov)

    draw = ImageDraw.Draw(img)
    text_x = badge_x + (badge_w - tw) // 2
    text_y = badge_y_center + (badge_h - (bb[3] - bb[1])) // 2 - int(2 * scale)
    draw.text((text_x, text_y), badge_text, fill=(10, 30, 80), font=ft)


def process(cfg, raw_dir, out_dir, w, h, text_h, pad, corner, title_sz):
    raw_key = "ipad" if raw_dir == IPAD_DIR else "raw"
    raw_name = cfg.get(raw_key, cfg["raw"])
    raw_path = raw_dir / raw_name
    if not raw_path.exists():
        print(f"  SKIP: {raw_name} not found")
        return

    scale = w / 1290

    # Dark gradient background
    final = Image.new("RGBA", (w, h))
    draw_gradient(final, cfg["bg_colors"][0], cfg["bg_colors"][1])

    # Decorative circles
    draw_circles(final, cfg["circles"], w, text_h)

    # Dot pattern
    draw_dot_pattern(final, w, h, text_h)

    # Badge (first screenshot only)
    if cfg["show_badge"]:
        draw_badge(final, w, scale)

    # Text lines
    draw = ImageDraw.Draw(final)
    draw_text_lines(draw, cfg, w, title_sz, scale)

    # Screenshot with shadow and rotation
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

    # Round corners
    mask = rounded_mask(raw.size, corner)
    rounded = Image.new("RGBA", raw.size, (0, 0, 0, 0))
    rounded.paste(raw, (0, 0), mask)

    # Add shadow
    with_shadow = add_shadow_to_screenshot(rounded, offset=int(12 * scale), blur=int(25 * scale))

    # Rotate
    angle = cfg["rotate"]
    rotated = rotate_screenshot(with_shadow, angle)

    # Position - center horizontally, fit from text_h downward
    px = (w - rotated.width) // 2
    py = text_h + (h - text_h - rotated.height) // 2
    if py < text_h:
        py = text_h

    final.paste(rotated, (px, py), rotated)

    out_path = out_dir / cfg["out"]
    final.convert("RGB").save(out_path, "PNG")
    kb = out_path.stat().st_size / 1024
    print(f"  {cfg['out']} ({w}x{h}, {kb:.0f}KB)")


def main():
    print("=== iPhone 6.7-inch (1290x2796) ===")
    for c in CONFIGS:
        process(c, RAW_DIR, IPHONE_OUT, IP_W, IP_H, IP_TEXT_H, IP_PAD,
                IP_CORNER, IP_TITLE_SZ)

    # IAP review (no overlay)
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
                PD_CORNER, PD_TITLE_SZ)

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
