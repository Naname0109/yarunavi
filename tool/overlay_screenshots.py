#!/usr/bin/env python3
"""App Store スクリーンショットにマーケティングテキストをオーバーレイする"""

import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# --- 設定 ---
RAW_DIR = Path(__file__).parent.parent / "screenshots" / "raw"
FINAL_DIR = Path(__file__).parent.parent / "screenshots" / "final"
FINAL_DIR.mkdir(parents=True, exist_ok=True)

FINAL_W, FINAL_H = 1284, 2778
TEXT_AREA_H = 480
SCREENSHOT_PADDING = 36
CORNER_RADIUS = 28

FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"
FONT_REGULAR = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
TITLE_SIZE = 72
SUB_SIZE = 40

# 各画像の設定: (raw_file, final_file, line1, line2, bg_top, bg_bottom, text_color)
CONFIGS = [
    (
        "raw_01_home.png",
        "final_01_home.png",
        "やることを入れるだけ。",
        "AIが整理してくれる。",
        (220, 230, 255),   # 青パステル
        (180, 200, 255),
        (30, 40, 120),
    ),
    (
        "raw_02_ai_result.png",
        "final_02_ai_result.png",
        "AIが優先順位を判断",
        "具体的なアドバイス付き",
        (240, 220, 255),   # 紫パステル
        (210, 180, 255),
        (60, 20, 120),
    ),
    (
        "raw_03_calendar.png",
        "final_03_calendar.png",
        "いつやるかが",
        "一目でわかる",
        (220, 255, 230),   # 緑パステル
        (180, 240, 200),
        (20, 80, 40),
    ),
    (
        "raw_04_ai_comment.png",
        "final_04_ai_comment.png",
        "AIが具体的にアドバイス",
        "タスクごとに最適な行動を提案",
        (255, 235, 220),   # オレンジパステル
        (255, 210, 180),
        (120, 50, 10),
    ),
    (
        "raw_05_onboarding.png",
        "final_05_notification.png",
        "やるべき日に通知。",
        "忘れない。",
        (255, 225, 235),   # ピンクパステル
        (255, 200, 220),
        (120, 20, 60),
    ),
]


def make_rounded_mask(size, radius):
    """角丸マスクを作成"""
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, w, h], radius=radius, fill=255)
    return mask


def draw_blurred_circles(img, bg_top, bg_bottom):
    """パステル背景にぼかし円の装飾を追加"""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # 装飾円の設定 (x_ratio, y_ratio, radius, color, alpha)
    circles = [
        (0.15, 0.12, 120, bg_bottom, 80),
        (0.80, 0.06, 90, bg_top, 60),
        (0.50, 0.18, 70, (255, 255, 255), 50),
    ]

    for xr, yr, r, color, alpha in circles:
        x = int(img.width * xr)
        y = int(TEXT_AREA_H * yr)
        draw.ellipse(
            [x - r, y - r, x + r, y + r],
            fill=(*color, alpha),
        )

    # ぼかし
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=40))
    img.paste(Image.alpha_composite(
        Image.new("RGBA", img.size, (0, 0, 0, 0)),
        overlay,
    ), (0, 0), overlay)


def process_image(raw_name, final_name, line1, line2, bg_top, bg_bottom, text_color):
    """1枚のスクリーンショットを加工"""
    raw_path = RAW_DIR / raw_name
    if not raw_path.exists():
        print(f"  SKIP: {raw_name} not found")
        return

    # 最終画像（グラデーション背景）
    final = Image.new("RGBA", (FINAL_W, FINAL_H), (*bg_top, 255))
    draw = ImageDraw.Draw(final)

    # グラデーション背景
    for y in range(FINAL_H):
        ratio = y / FINAL_H
        r = int(bg_top[0] + (bg_bottom[0] - bg_top[0]) * ratio)
        g = int(bg_top[1] + (bg_bottom[1] - bg_top[1]) * ratio)
        b = int(bg_top[2] + (bg_bottom[2] - bg_top[2]) * ratio)
        draw.line([(0, y), (FINAL_W, y)], fill=(r, g, b, 255))

    # ぼかし円装飾
    draw_blurred_circles(final, bg_top, bg_bottom)

    # テキスト描画
    draw = ImageDraw.Draw(final)
    font_title = ImageFont.truetype(FONT_BOLD, TITLE_SIZE)
    font_sub = ImageFont.truetype(FONT_REGULAR, SUB_SIZE)

    # タイトル（1行目）
    bbox1 = draw.textbbox((0, 0), line1, font=font_title)
    tw1 = bbox1[2] - bbox1[0]
    x1 = (FINAL_W - tw1) // 2
    y1 = 120
    draw.text((x1, y1), line1, fill=text_color, font=font_title)

    # サブテキスト（2行目）
    bbox2 = draw.textbbox((0, 0), line2, font=font_sub)
    tw2 = bbox2[2] - bbox2[0]
    x2 = (FINAL_W - tw2) // 2
    y2 = y1 + TITLE_SIZE + 30
    draw.text((x2, y2), line2, fill=(*text_color, 200), font=font_sub)

    # スクリーンショット読み込み・リサイズ
    raw_img = Image.open(raw_path).convert("RGBA")
    ss_w = FINAL_W - SCREENSHOT_PADDING * 2
    ss_h = FINAL_H - TEXT_AREA_H - SCREENSHOT_PADDING
    raw_img = raw_img.resize((ss_w, ss_h), Image.LANCZOS)

    # 角丸マスク適用
    mask = make_rounded_mask(raw_img.size, CORNER_RADIUS)
    rounded = Image.new("RGBA", raw_img.size, (0, 0, 0, 0))
    rounded.paste(raw_img, (0, 0), mask)

    # スクリーンショットを配置
    paste_x = SCREENSHOT_PADDING
    paste_y = TEXT_AREA_H
    final.paste(rounded, (paste_x, paste_y), rounded)

    # 保存（RGB変換）
    final_path = FINAL_DIR / final_name
    final.convert("RGB").save(final_path, "PNG")
    size_kb = final_path.stat().st_size / 1024
    print(f"  OK: {final_name} ({FINAL_W}x{FINAL_H}, {size_kb:.0f}KB)")


def main():
    print("=== Marketing overlay processing ===")

    for config in CONFIGS:
        process_image(*config)

    # IAP: そのまま final にコピー（リサイズのみ）
    iap_src = RAW_DIR / "raw_iap.png"
    iap_dst = FINAL_DIR / "iap_review.png"
    if iap_src.exists():
        img = Image.open(iap_src)
        img = img.resize((FINAL_W, FINAL_H), Image.LANCZOS)
        img.save(iap_dst, "PNG")
        size_kb = iap_dst.stat().st_size / 1024
        print(f"  OK: iap_review.png ({FINAL_W}x{FINAL_H}, {size_kb:.0f}KB)")

    print("\n=== Done ===")
    print(f"Output: {FINAL_DIR}")


if __name__ == "__main__":
    main()
