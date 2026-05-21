#!/usr/bin/env python3
"""App Store screenshot overlay v2 — Claude Design (aso-frames.jsx).

JSX のレイアウト・色・グロー・テキストを Pillow + numpy で再現する。

入力 (raw screenshots, dark UI 推奨):
  screenshots/raw_dark/raw_*.png     (1320x2868)
  screenshots/ipad_dark/ipad_*.png   (2064x2752)

出力:
  ios/fastlane/screenshots/ja/iPhone 6.7-inch/01_hero_left ... 06_premium .png
  ios/fastlane/screenshots/ja/iPhone 6.5-inch/ (resize)
  ios/fastlane/screenshots/ja/iPad Pro 12.9-inch/
  ios/fastlane/screenshots/en-US/ ... (同構成、 英訳)

CLI:
  python3 tool/overlay_screenshots_v2.py            # ja + en, iPhone + iPad
  python3 tool/overlay_screenshots_v2.py --lang ja  # ja のみ
  python3 tool/overlay_screenshots_v2.py --device iphone  # iPhone のみ
  python3 tool/overlay_screenshots_v2.py --light    # ライト UI raw を使用
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

PROJECT = Path(__file__).parent.parent
RAW_DARK = PROJECT / "screenshots" / "raw_dark"
RAW_LIGHT = PROJECT / "screenshots" / "raw_light"
IPAD_DARK = PROJECT / "screenshots" / "ipad_dark"
IPAD_LIGHT = PROJECT / "screenshots" / "ipad_light"

OUT_JA_67 = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPhone 6.7-inch"
OUT_JA_65 = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPhone 6.5-inch"
OUT_JA_IPAD = PROJECT / "ios" / "fastlane" / "screenshots" / "ja" / "iPad Pro 12.9-inch"
OUT_EN_67 = PROJECT / "ios" / "fastlane" / "screenshots" / "en-US" / "iPhone 6.7-inch"
OUT_EN_65 = PROJECT / "ios" / "fastlane" / "screenshots" / "en-US" / "iPhone 6.5-inch"
OUT_EN_IPAD = PROJECT / "ios" / "fastlane" / "screenshots" / "en-US" / "iPad Pro 12.9-inch"

# Fonts (Hiragino)
FONT_HEAVY = "/System/Library/Fonts/ヒラギノ角ゴシック W9.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"
FONT_SEMI = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"

# iPhone 6.7" final size
IP_W, IP_H = 1290, 2796
# iPad 12.9" final size (3rd Gen)
PD_W, PD_H = 2048, 2732


# ============================================================
# Utility: color
# ============================================================

def hex_rgba(hex_str: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def with_alpha(rgb: tuple[int, int, int, int], a: int) -> tuple[int, int, int, int]:
    return (rgb[0], rgb[1], rgb[2], a)


# ============================================================
# Background: radial-gradient(W H at cx cy, c0 0%, c1 mid, c2 100%)
# ============================================================

def draw_radial_bg(
    w: int, h: int,
    center_pct: tuple[float, float],
    radius_pct: tuple[float, float],
    stops: list[tuple[float, tuple[int, int, int]]],
) -> Image.Image:
    cx, cy = center_pct[0] * w, center_pct[1] * h
    rx, ry = radius_pct[0] * w, radius_pct[1] * h
    Y, X = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2)
    d = np.clip(d, 0, 1)

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[..., 3] = 255

    sorted_stops = sorted(stops, key=lambda x: x[0])
    # 0 未満も入れる
    for i in range(len(sorted_stops) - 1):
        s0, c0 = sorted_stops[i]
        s1, c1 = sorted_stops[i + 1]
        mask = (d >= s0) & (d <= s1)
        denom = max(s1 - s0, 1e-6)
        t = (d[mask] - s0) / denom
        for ci in range(3):
            rgba[..., ci][mask] = (c0[ci] * (1 - t) + c1[ci] * t).astype(np.uint8)

    # > 最大 stop の領域は最後の色
    above = d > sorted_stops[-1][0]
    for ci in range(3):
        rgba[..., ci][above] = sorted_stops[-1][1][ci]

    return Image.fromarray(rgba, "RGBA")


# ============================================================
# Dotted background
# ============================================================

def draw_dots(canvas: Image.Image, color_rgba: tuple[int, int, int, int],
              spacing: int = 22, dot_radius: float = 1.4):
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    r = dot_radius
    for x in range(0, canvas.width, spacing):
        for y in range(0, canvas.height, spacing):
            d.ellipse([x - r, y - r, x + r, y + r], fill=color_rgba)
    canvas.alpha_composite(overlay)


# ============================================================
# Radial glow (circular soft light)
# ============================================================

def draw_glow(canvas: Image.Image,
              center_pct: tuple[float, float],
              size: int,
              color_rgba: tuple[int, int, int, int]):
    w, h = canvas.size
    cx, cy = center_pct[0] * w, center_pct[1] * h

    # Falloff: color at 0, transparent at radius (size/2) * (1/0.6) なので
    # JSX の `circle, color 0%, transparent 60%` を再現するため
    # alpha = color_a * max(0, 1 - d/(falloff))
    falloff_r = (size / 2) / 0.6
    bbox = (
        max(0, int(cx - falloff_r)), max(0, int(cy - falloff_r)),
        min(w, int(cx + falloff_r) + 1), min(h, int(cy + falloff_r) + 1),
    )
    if bbox[2] <= bbox[0] or bbox[3] <= bbox[1]:
        return
    Y, X = np.mgrid[bbox[1]:bbox[3], bbox[0]:bbox[2]].astype(np.float32)
    d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    t = np.clip(1 - d / falloff_r, 0, 1)
    # falloff を強める (60% で透明 → t を 0.6 で透明化)
    t = np.clip(t * (1 / 0.4) - (0.6 / 0.4), 0, 1) ** 1.4
    sub_h, sub_w = t.shape
    arr = np.zeros((sub_h, sub_w, 4), dtype=np.uint8)
    arr[..., 0] = color_rgba[0]
    arr[..., 1] = color_rgba[1]
    arr[..., 2] = color_rgba[2]
    arr[..., 3] = (color_rgba[3] * t).astype(np.uint8)
    glow_img = Image.fromarray(arr, "RGBA")
    canvas.alpha_composite(glow_img, (bbox[0], bbox[1]))


# ============================================================
# Phone frame (rounded bezel + dynamic island + drop glow)
# ============================================================

def make_phone_frame(
    screenshot_path: Path, width: int, height: int,
    glow_color: tuple[int, int, int] | None,
) -> tuple[Image.Image, int]:
    """端末フレーム RGBA + glow 用 padding を返す。"""
    bezel = round(width * 0.020)
    radius = round(width * 0.115)
    inner_radius = max(radius - bezel + 2, 1)
    screen_w = width - bezel * 2
    screen_h = height - bezel * 2

    # ベゼル外形 (linear gradient #1a1f30 → #0a0d18)
    bg = np.zeros((height, width, 4), dtype=np.uint8)
    for yy in range(height):
        t = yy / max(height - 1, 1)
        c0 = (26, 31, 48)
        c1 = (10, 13, 24)
        bg[yy, :, 0] = int(c0[0] * (1 - t) + c1[0] * t)
        bg[yy, :, 1] = int(c0[1] * (1 - t) + c1[1] * t)
        bg[yy, :, 2] = int(c0[2] * (1 - t) + c1[2] * t)
        bg[yy, :, 3] = 255
    bezel_img = Image.fromarray(bg, "RGBA")
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, width - 1, height - 1], radius=radius, fill=255
    )
    bezel_img.putalpha(mask)

    # スクリーン部分: raw screenshot を bezel 内に貼る
    ss = Image.open(screenshot_path).convert("RGBA")
    # アスペクト合わせ: screen に内接させる (cropなし、 letterboxで歪まないように)
    src_w, src_h = ss.size
    src_ratio = src_w / src_h
    dst_ratio = screen_w / screen_h
    if abs(src_ratio - dst_ratio) < 0.005:
        ss_fit = ss.resize((screen_w, screen_h), Image.LANCZOS)
    elif src_ratio > dst_ratio:
        # src が横長 → 幅基準 + 上下 letterbox (raw が縦長想定で来るのでこの分岐は稀)
        new_h = int(screen_w / src_ratio)
        resized = ss.resize((screen_w, new_h), Image.LANCZOS)
        ss_fit = Image.new("RGBA", (screen_w, screen_h), (4, 8, 24, 255))
        ss_fit.paste(resized, (0, (screen_h - new_h) // 2))
    else:
        # src が縦長 → 高さ基準 + 左右 letterbox
        new_w = int(screen_h * src_ratio)
        resized = ss.resize((new_w, screen_h), Image.LANCZOS)
        ss_fit = Image.new("RGBA", (screen_w, screen_h), (4, 8, 24, 255))
        ss_fit.paste(resized, ((screen_w - new_w) // 2, 0))

    ss_mask = Image.new("L", (screen_w, screen_h), 0)
    ImageDraw.Draw(ss_mask).rounded_rectangle(
        [0, 0, screen_w - 1, screen_h - 1], radius=inner_radius, fill=255
    )
    ss_rgba = ss_fit.copy()
    ss_rgba.putalpha(ss_mask)
    bezel_img.alpha_composite(ss_rgba, (bezel, bezel))

    # ダイナミックアイランド (28% × 7% of width, 黒)
    di_w = int(width * 0.28)
    di_h = int(width * 0.07)
    di_x = (width - di_w) // 2
    di_y = int(bezel * 0.55) + bezel  # bezel 領域内に
    # JSX では bezel padding 内に position absolute なので
    # bezel offset の上に bezel*0.55
    di_y = bezel + int(bezel * 0.55) - di_h // 2 + int(bezel * 0.3)
    # 実装簡便化: 画面 top から bezel + small offset で配置
    di_y = bezel + int(width * 0.012)
    di_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(di_layer).rounded_rectangle(
        [di_x, di_y, di_x + di_w, di_y + di_h], radius=di_h // 2, fill=(0, 0, 0, 255)
    )
    bezel_img.alpha_composite(di_layer)

    # glow halo は呼び出し側で適用 (端末の x,y を知る必要があるので)
    # ここでは frame 本体だけ返す
    pad = 0
    if glow_color:
        pad = 120
    return bezel_img, pad


def paste_phone_with_glow(
    canvas: Image.Image,
    frame: Image.Image,
    x: int, y: int,
    glow_color: tuple[int, int, int] | None,
):
    if glow_color is not None:
        # 端末外周に soft halo (80px blur, 端末より +outer の角丸 rectangle)
        gw, gh = frame.size
        pad = 120
        halo = Image.new("RGBA", (gw + pad * 2, gh + pad * 2), (0, 0, 0, 0))
        halo_draw = ImageDraw.Draw(halo)
        radius = round(gw * 0.115)
        halo_draw.rounded_rectangle(
            [pad - 20, pad - 20, pad + gw + 20, pad + gh + 20],
            radius=radius + 20,
            fill=(*glow_color, 110),
        )
        halo = halo.filter(ImageFilter.GaussianBlur(radius=70))
        canvas.alpha_composite(halo, (x - pad, y - pad))

    # 端末 drop shadow
    sh_pad = 60
    shadow = Image.new("RGBA", (frame.width + sh_pad * 2, frame.height + sh_pad * 2), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    radius = round(frame.width * 0.115)
    sd.rounded_rectangle(
        [sh_pad, sh_pad + 30, sh_pad + frame.width, sh_pad + frame.height + 30],
        radius=radius, fill=(0, 0, 0, 180),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=35))
    canvas.alpha_composite(shadow, (x - sh_pad, y - sh_pad))

    canvas.alpha_composite(frame, (x, y))


# ============================================================
# Headline text rendering
# ============================================================

@dataclass
class TitleSegment:
    text: str
    accent: bool = False


def _font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype(FONT_BOLD, size)


def measure(text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    bb = font.getbbox(text)
    return bb[2] - bb[0], bb[3] - bb[1]


def draw_eyebrow_badge(
    canvas: Image.Image,
    text: str,
    cx: int, cy: int,
    color: tuple[int, int, int],
    icon: str | None = None,
    font_size: int = 36,
):
    """ガラス背景の eyebrow badge を中央 (cx, cy) に描画。"""
    font = _font(FONT_BOLD, font_size)
    icon_text = icon or ""
    text_full = f"{icon_text}  {text}" if icon_text else text
    tw, th = measure(text_full, font)
    pad_x = 36
    pad_y = 16
    bw = tw + pad_x * 2
    bh = th + pad_y * 2
    x0 = cx - bw // 2
    y0 = cy - bh // 2
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    # 背景: 半透明 + ボーダー
    od.rounded_rectangle(
        [x0, y0, x0 + bw, y0 + bh],
        radius=bh // 2, fill=(*color, 22),
        outline=(*color, 110), width=2,
    )
    # テキスト (アイコンも色を eyebrow color に)
    od.text((x0 + pad_x, y0 + pad_y - 4), text_full, font=font, fill=(*color, 255))
    canvas.alpha_composite(overlay)


def draw_title_lines(
    canvas: Image.Image,
    lines: list[list[TitleSegment]],
    cx: int, top: int,
    base_color: tuple[int, int, int],
    accent_color: tuple[int, int, int],
    title_size: int,
    line_spacing_ratio: float = 1.16,
    *,
    accent_grad: tuple[tuple[int, int, int], tuple[int, int, int]] | None = None,
) -> int:
    """複数行タイトルを描画して、 描画後の bottom Y を返す。"""
    font = _font(FONT_HEAVY, title_size)
    line_h = int(title_size * line_spacing_ratio)
    y = top

    for line in lines:
        # ラインの total width 計算
        total_w = 0
        widths = []
        for seg in line:
            w, _ = measure(seg.text, font)
            widths.append(w)
            total_w += w
        x = cx - total_w // 2

        for seg, w in zip(line, widths):
            if seg.accent and accent_grad:
                # グラデーションテキスト
                _draw_gradient_text(canvas, seg.text, font, (x, y), accent_grad)
            else:
                color = accent_color if seg.accent else base_color
                # ImageDraw.text に直接描画 (canvas 上で)
                d = ImageDraw.Draw(canvas)
                d.text((x, y), seg.text, font=font, fill=(*color, 255))
            x += w

        y += line_h

    return y


def _draw_gradient_text(
    canvas: Image.Image,
    text: str,
    font: ImageFont.FreeTypeFont,
    pos: tuple[int, int],
    grad: tuple[tuple[int, int, int], tuple[int, int, int]],
):
    """テキストの左→右にグラデーション。"""
    w, h = measure(text, font)
    if w <= 0 or h <= 0:
        return
    # bbox 余裕を取る (descender 等)
    pad_y_top = font.getbbox(text)[1]
    full_h = h + max(0, font.getbbox(text)[3] - h) + abs(pad_y_top)
    full_h = max(int(font.size * 1.4), full_h)

    # mask
    text_mask = Image.new("L", (w + 4, full_h + 20), 0)
    md = ImageDraw.Draw(text_mask)
    md.text((-font.getbbox(text)[0], -font.getbbox(text)[1]), text, font=font, fill=255)

    # gradient
    gw, gh = text_mask.size
    grad_img = np.zeros((gh, gw, 4), dtype=np.uint8)
    c0, c1 = grad
    for xi in range(gw):
        t = xi / max(gw - 1, 1)
        grad_img[:, xi, 0] = int(c0[0] * (1 - t) + c1[0] * t)
        grad_img[:, xi, 1] = int(c0[1] * (1 - t) + c1[1] * t)
        grad_img[:, xi, 2] = int(c0[2] * (1 - t) + c1[2] * t)
        grad_img[:, xi, 3] = 255
    gimg = Image.fromarray(grad_img, "RGBA")
    gimg.putalpha(text_mask)
    canvas.alpha_composite(gimg, (pos[0], pos[1] + font.getbbox(text)[1]))


def draw_sub(
    canvas: Image.Image,
    text: str, cx: int, y: int,
    color: tuple[int, int, int, int] = (255, 255, 255, 165),
    size: int = 34,
):
    font = _font(FONT_SEMI, size)
    w, h = measure(text, font)
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.text((cx - w // 2, y), text, font=font, fill=color)
    canvas.alpha_composite(overlay)


# ============================================================
# Frame configs
# ============================================================

@dataclass
class FrameConfig:
    name: str
    bg_stops: list[tuple[float, tuple[int, int, int]]]
    glows: list[tuple[tuple[float, float], int, tuple[int, int, int, int]]]
    # eyebrow
    eyebrow_icon: str  # emoji or "✨ etc"
    eyebrow_text: str
    eyebrow_color: tuple[int, int, int]
    # title
    title_lines: list[list[TitleSegment]]
    title_size: int
    accent_color: tuple[int, int, int]
    # sub
    sub_text: str
    # phone screenshot
    raw_filename: str
    phone_glow: tuple[int, int, int]


# Localized text
TEXTS_JA = {
    "calendar": {
        "eyebrow_icon": "📅",
        "eyebrow_text": "カレンダー連動",
        "title": [
            [TitleSegment("予定も進捗も、")],
            [TitleSegment("ひと目", accent=True), TitleSegment("でわかる。")],
        ],
        "sub": "緊急 · 今週 · 来週を、色で見分ける",
    },
    "reminder": {
        "eyebrow_icon": "🔔",
        "eyebrow_text": "締切リマインド",
        "title": [
            [TitleSegment("うっかり忘れを、")],
            [TitleSegment("ゼロに", accent=True), TitleSegment("。")],
        ],
        "sub": "残り時間を、刻一刻と表示",
    },
    "quick": {
        "eyebrow_icon": "⚡",
        "eyebrow_text": "かんたん登録",
        "title": [
            [TitleSegment("2秒", accent=True), TitleSegment("で登録、")],
            [TitleSegment("あとはAIに。")],
        ],
        "sub": "日付もメモも、後からでOK",
    },
    "premium": {
        "eyebrow_icon": "🏅",
        "eyebrow_text": "PREMIUM",
        "title": [
            [TitleSegment("プレミアムで、")],
            [TitleSegment("無制限", accent=True), TitleSegment("へ。")],
        ],
        "sub": "広告非表示・AI整理 月30回・全機能解放",
    },
    "hero": {
        "eyebrow_icon": "✨",
        "eyebrow_text": "AI × タスク管理",
        "title_l1": "登録するだけ。",
        "title_l2_pre": "",
        "title_l2_accent": "AI",
        "title_l2_post": "が今日の道筋を作る。",
        "sub": "書き出す → 優先順位を提案 → 迷わず動ける",
        "step1_text": "STEP 01",
        "step1_caption": "書き出す",
        "step2_text": "STEP 02",
        "step2_caption": "AIが整理",
    },
}

TEXTS_EN = {
    "calendar": {
        "eyebrow_icon": "📅",
        "eyebrow_text": "Calendar Sync",
        "title": [
            [TitleSegment("See it all,")],
            [TitleSegment("at a glance", accent=True), TitleSegment(".")],
        ],
        "sub": "Urgent · This week · Later — color-coded",
    },
    "reminder": {
        "eyebrow_icon": "🔔",
        "eyebrow_text": "Deadline Reminders",
        "title": [
            [TitleSegment("Never miss")],
            [TitleSegment("a deadline", accent=True), TitleSegment(".")],
        ],
        "sub": "Live countdown to every due date",
    },
    "quick": {
        "eyebrow_icon": "⚡",
        "eyebrow_text": "Quick Capture",
        "title": [
            [TitleSegment("Add in 2s", accent=True), TitleSegment(",")],
            [TitleSegment("AI does the rest.")],
        ],
        "sub": "Dates and notes can come later",
    },
    "premium": {
        "eyebrow_icon": "🏅",
        "eyebrow_text": "PREMIUM",
        "title": [
            [TitleSegment("Premium —")],
            [TitleSegment("go unlimited", accent=True), TitleSegment(".")],
        ],
        "sub": "Ad-free · 30 AI sorts/month · All features",
    },
    "hero": {
        "eyebrow_icon": "✨",
        "eyebrow_text": "AI × Task Manager",
        "title_l1": "Just write it down.",
        "title_l2_pre": "",
        "title_l2_accent": "AI",
        "title_l2_post": " maps your day.",
        "sub": "Capture → Prioritize → Act without doubt",
        "step1_text": "STEP 01",
        "step1_caption": "Capture",
        "step2_text": "STEP 02",
        "step2_caption": "AI sorts",
    },
}


def build_single_configs(texts: dict, raw_dir: Path) -> list[FrameConfig]:
    return [
        FrameConfig(
            name="03_calendar",
            bg_stops=[(0.0, (13, 43, 61)), (0.6, (5, 22, 36)), (1.0, (2, 8, 15))],
            glows=[((0.5, 0.0), 1100, (74, 217, 184, 200))],
            eyebrow_icon=texts["calendar"]["eyebrow_icon"],
            eyebrow_text=texts["calendar"]["eyebrow_text"],
            eyebrow_color=(74, 217, 184),
            title_lines=texts["calendar"]["title"],
            title_size=120,
            accent_color=(74, 217, 184),
            sub_text=texts["calendar"]["sub"],
            raw_filename="raw_03_calendar.png",
            phone_glow=(74, 217, 184),
        ),
        FrameConfig(
            name="04_reminder",
            bg_stops=[(0.0, (58, 10, 30)), (0.5, (26, 6, 18)), (1.0, (8, 2, 10))],
            glows=[((0.5, 0.05), 1200, (255, 77, 141, 200))],
            eyebrow_icon=texts["reminder"]["eyebrow_icon"],
            eyebrow_text=texts["reminder"]["eyebrow_text"],
            eyebrow_color=(255, 122, 171),
            title_lines=texts["reminder"]["title"],
            title_size=124,
            accent_color=(255, 122, 171),
            sub_text=texts["reminder"]["sub"],
            raw_filename="raw_04_ai_comment.png",
            phone_glow=(255, 93, 138),
        ),
        FrameConfig(
            name="05_quick_add",
            bg_stops=[(0.0, (26, 40, 86)), (0.55, (10, 20, 56)), (1.0, (3, 6, 26))],
            glows=[((0.5, 0.05), 1100, (125, 245, 237, 200))],
            eyebrow_icon=texts["quick"]["eyebrow_icon"],
            eyebrow_text=texts["quick"]["eyebrow_text"],
            eyebrow_color=(125, 245, 237),
            title_lines=texts["quick"]["title"],
            title_size=124,
            accent_color=(125, 245, 237),
            sub_text=texts["quick"]["sub"],
            raw_filename="raw_05_simple_input.png",
            phone_glow=(125, 245, 237),
        ),
        FrameConfig(
            name="06_premium",
            bg_stops=[(0.0, (12, 41, 53)), (0.5, (6, 21, 32)), (1.0, (2, 6, 12))],
            glows=[
                ((0.5, 0.0), 1200, (125, 245, 237, 200)),
                ((0.5, 0.9), 900, (180, 140, 255, 140)),
            ],
            eyebrow_icon=texts["premium"]["eyebrow_icon"],
            eyebrow_text=texts["premium"]["eyebrow_text"],
            eyebrow_color=(125, 245, 237),
            title_lines=texts["premium"]["title"],
            title_size=122,
            accent_color=(125, 245, 237),
            sub_text=texts["premium"]["sub"],
            raw_filename="raw_iap.png",
            phone_glow=(125, 245, 237),
        ),
    ]


# ============================================================
# Renderers
# ============================================================

def render_single_frame(
    cfg: FrameConfig, raw_dir: Path,
    frame_size: tuple[int, int],
    phone_size: tuple[int, int],
    phone_bottom_offset: int,
    headline_top: int,
    title_size_override: int | None = None,
    eyebrow_font_override: int | None = None,
    sub_font_override: int | None = None,
) -> Image.Image:
    fw, fh = frame_size
    # 背景
    canvas = draw_radial_bg(
        fw, fh, center_pct=(0.5, 0.1), radius_pct=(1.10, 0.80),
        stops=cfg.bg_stops,
    )
    draw_dots(canvas, (255, 255, 255, 13))
    for (cpct, sz, col) in cfg.glows:
        draw_glow(canvas, cpct, sz, col)

    # ヘッドライン
    cx = fw // 2
    eyebrow_y = headline_top
    eyebrow_size = eyebrow_font_override or 36
    title_size = title_size_override or cfg.title_size
    sub_size = sub_font_override or 34
    draw_eyebrow_badge(canvas, cfg.eyebrow_text, cx, eyebrow_y,
                       cfg.eyebrow_color, icon=cfg.eyebrow_icon, font_size=eyebrow_size)
    title_y = eyebrow_y + max(80, eyebrow_size * 2)
    bottom = draw_title_lines(
        canvas, cfg.title_lines, cx, title_y,
        base_color=(255, 255, 255),
        accent_color=cfg.accent_color,
        title_size=title_size,
    )
    draw_sub(canvas, cfg.sub_text, cx, bottom + 24,
             color=(255, 255, 255, 170), size=sub_size)

    # 端末フレーム + raw (iPad raw は ipad_*.png prefix)
    raw_name = cfg.raw_filename
    if raw_dir.name.startswith("ipad"):
        raw_name = raw_name.replace("raw_", "ipad_", 1)
    raw_path = raw_dir / raw_name
    if not raw_path.exists():
        print(f"  WARN: {raw_path} not found, skip phone")
    else:
        pw, ph = phone_size
        frame, _ = make_phone_frame(raw_path, pw, ph, glow_color=cfg.phone_glow)
        px = (fw - pw) // 2
        py = fh - ph + phone_bottom_offset  # phone_bottom_offset は負で「画面外に飛び出す量」
        paste_phone_with_glow(canvas, frame, px, py, glow_color=cfg.phone_glow)

    return canvas


def render_hero_2up(
    texts: dict, raw_dir: Path,
    *, frame_w_each: int, frame_h: int,
    phone_w: int, phone_h: int,
    title_size: int,
    eyebrow_font_size: int,
    sub_font_size: int,
) -> tuple[Image.Image, Image.Image]:
    """連結ヒーロー: 全幅で描画して中央分割して 2 枚返す。"""
    full_w = frame_w_each * 2

    canvas = draw_radial_bg(
        full_w, frame_h, center_pct=(0.5, 0.1), radius_pct=(1.20, 0.70),
        stops=[(0.0, (14, 24, 69)), (0.6, (5, 11, 34)), (1.0, (2, 5, 15))],
    )
    draw_dots(canvas, (255, 255, 255, 10))
    draw_glow(canvas, (0.35, 0.2), int(1300 * (frame_w_each / 1290)),
              (125, 245, 237, 200))
    draw_glow(canvas, (0.70, 0.15), int(1100 * (frame_w_each / 1290)),
              (180, 140, 255, 180))

    # ヘッドライン (中央)
    cx = full_w // 2
    headline_top = int(170 * (frame_h / 2796))
    h = texts["hero"]
    draw_eyebrow_badge(canvas, h["eyebrow_text"], cx, headline_top,
                       (125, 245, 237), icon=h["eyebrow_icon"],
                       font_size=eyebrow_font_size)

    # タイトル 2 行
    title_y = headline_top + 90
    font = _font(FONT_HEAVY, title_size)
    # 1行目: "登録するだけ。" (white)
    l1 = h["title_l1"]
    w1, _ = measure(l1, font)
    d = ImageDraw.Draw(canvas)
    d.text((cx - w1 // 2, title_y), l1, font=font, fill=(255, 255, 255, 255))

    # 2行目: pre + AI (gradient) + post
    l2_pre = h["title_l2_pre"]
    l2_acc = h["title_l2_accent"]
    l2_post = h["title_l2_post"]
    line_h = int(title_size * 1.12)
    w_pre, _ = measure(l2_pre, font) if l2_pre else (0, 0)
    w_acc, _ = measure(l2_acc, font)
    w_post, _ = measure(l2_post, font)
    total = w_pre + w_acc + w_post
    x = cx - total // 2
    y2 = title_y + line_h
    if l2_pre:
        d.text((x, y2), l2_pre, font=font, fill=(255, 255, 255, 255))
        x += w_pre
    _draw_gradient_text(canvas, l2_acc, font, (x, y2),
                        ((125, 245, 237), (180, 140, 255)))
    x += w_acc
    d.text((x, y2), l2_post, font=font, fill=(255, 255, 255, 255))

    # サブテキスト
    sub_y = y2 + line_h - int(title_size * 0.1) + 24
    draw_sub(canvas, h["sub"], cx, sub_y, color=(255, 255, 255, 165),
             size=sub_font_size)

    # 端末 2 台 + 中央 connector
    # 配置: 中央付近に近接、 phone_w + gap*2 + phone_w が full_w に収まるよう
    gap = int(100 * (frame_w_each / 1290))
    total_phone_w = phone_w * 2 + gap
    px_left = (full_w - total_phone_w) // 2
    px_right = px_left + phone_w + gap
    # 端末 bottom を少し画面外に飛び出す ( -160 of JSX)
    py = frame_h - phone_h - int(-160 * (frame_h / 2796))

    prefix = "ipad_" if raw_dir.name.startswith("ipad") else "raw_"
    raw1 = raw_dir / f"{prefix}01_home.png"
    raw2 = raw_dir / f"{prefix}02_ai_result.png"
    if raw1.exists():
        f1, _ = make_phone_frame(raw1, phone_w, phone_h, glow_color=(125, 245, 237))
        paste_phone_with_glow(canvas, f1, px_left, py, glow_color=(125, 245, 237))
    if raw2.exists():
        f2, _ = make_phone_frame(raw2, phone_w, phone_h, glow_color=(180, 140, 255))
        paste_phone_with_glow(canvas, f2, px_right, py, glow_color=(180, 140, 255))

    # ステップバッジ (端末上に float)
    _draw_step_badge(canvas, h["step1_text"], h["step1_caption"],
                     px_left + 30, py - 130, (125, 245, 237))
    _draw_step_badge(canvas, h["step2_text"], h["step2_caption"],
                     px_right + phone_w - 30, py - 130, (180, 140, 255),
                     align="right")

    # 中央 connector (140px の円, gradient + 矢印)
    cn_size = int(140 * (frame_h / 2796))
    cn_cx = full_w // 2
    cn_cy = py + int(phone_h * 0.52)
    _draw_connector(canvas, cn_cx, cn_cy, cn_size,
                    ((125, 245, 237), (180, 140, 255)))

    # 中央で分割して 2 枚
    left = canvas.crop((0, 0, frame_w_each, frame_h))
    right = canvas.crop((frame_w_each, 0, full_w, frame_h))
    return left, right


def _draw_step_badge(
    canvas: Image.Image,
    step: str, caption: str,
    anchor_x: int, anchor_y: int,
    color: tuple[int, int, int],
    align: str = "left",
):
    font_step = _font(FONT_BOLD, 18)
    font_cap = _font(FONT_BOLD, 32)
    step_w, _ = measure(step, font_step)
    cap_w, _ = measure(caption, font_cap)
    pad_x = 22
    pad_y = 14
    chip_w = step_w + 20
    chip_h = 30
    gap = 14
    total_w = chip_w + gap + cap_w
    bh = max(chip_h, 36) + pad_y * 2

    if align == "right":
        x0 = anchor_x - (total_w + pad_x * 2)
    else:
        x0 = anchor_x
    y0 = anchor_y

    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    # 背景: 半透明 navy + glow
    od.rounded_rectangle(
        [x0, y0, x0 + total_w + pad_x * 2, y0 + bh],
        radius=bh // 2, fill=(10, 18, 48, 210),
        outline=(*color, 110), width=2,
    )
    # STEP chip
    chip_x = x0 + pad_x
    chip_y = y0 + (bh - chip_h) // 2
    od.rounded_rectangle(
        [chip_x, chip_y, chip_x + chip_w, chip_y + chip_h],
        radius=chip_h // 2, fill=(*color, 40), outline=(*color, 100), width=1,
    )
    od.text((chip_x + 10, chip_y + 5), step, font=font_step, fill=(*color, 255))
    # caption
    cap_x = chip_x + chip_w + gap
    cap_y = y0 + (bh - 40) // 2 - 2
    od.text((cap_x, cap_y), caption, font=font_cap, fill=(255, 255, 255, 255))
    canvas.alpha_composite(overlay)


def _draw_connector(
    canvas: Image.Image, cx: int, cy: int, size: int,
    grad: tuple[tuple[int, int, int], tuple[int, int, int]],
):
    layer = Image.new("RGBA", (size + 80, size + 80), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    pad = 40
    # 円の RGBA グラデ
    arr = np.zeros((size, size, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:size, 0:size]
    inside = ((xx - size / 2) ** 2 + (yy - size / 2) ** 2) <= (size / 2) ** 2
    # 角度 t: 135deg ≈ left-top -> right-bottom
    t = ((xx + yy) / (2 * size)).clip(0, 1)
    arr[..., 0] = (grad[0][0] * (1 - t) + grad[1][0] * t).astype(np.uint8)
    arr[..., 1] = (grad[0][1] * (1 - t) + grad[1][1] * t).astype(np.uint8)
    arr[..., 2] = (grad[0][2] * (1 - t) + grad[1][2] * t).astype(np.uint8)
    arr[..., 3] = (inside * 255).astype(np.uint8)
    circle = Image.fromarray(arr, "RGBA")
    layer.alpha_composite(circle, (pad, pad))
    # 白い線 (border)
    ld.ellipse([pad, pad, pad + size, pad + size], outline=(255, 255, 255, 70), width=4)
    # 矢印テキスト
    font = _font(FONT_HEAVY, int(size * 0.5))
    aw, ah = measure("→", font)
    ld.text((pad + size // 2 - aw // 2, pad + size // 2 - ah // 2 - int(size * 0.1)),
            "→", font=font, fill=(6, 36, 61, 255))
    # glow 影
    glow_layer = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.ellipse([pad, pad, pad + size, pad + size], fill=(125, 245, 237, 80))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=40))
    canvas.alpha_composite(glow_layer, (cx - layer.width // 2, cy - layer.height // 2))
    canvas.alpha_composite(layer, (cx - layer.width // 2, cy - layer.height // 2))


# ============================================================
# Main pipeline
# ============================================================

def render_all_for_device(
    lang: str, device: str, raw_dir: Path, ipad_raw_dir: Path,
    out_dir: Path,
):
    texts = TEXTS_JA if lang == "ja" else TEXTS_EN
    out_dir.mkdir(parents=True, exist_ok=True)

    if device == "iphone":
        frame_w, frame_h = IP_W, IP_H
        phone_w = int(970 * (frame_w / 1290))   # 970
        phone_h = int(1980 * (frame_w / 1290))  # 1980
        hero_phone_w = int(1020 * (frame_w / 1290))
        hero_phone_h = int(2090 * (frame_w / 1290))
        title_size_hero = int(180 * (frame_w / 1290))
        eyebrow_font = 38
        sub_font = 42
        headline_top = 170
        phone_bottom_offset = -50
        raw_dir_use = raw_dir
    else:
        frame_w, frame_h = PD_W, PD_H
        # iPad raw アスペクト = 2064/2752 ≒ 0.75 (4:3)
        phone_w = 1620
        phone_h = 2160   # 1620/0.75 = 2160
        hero_phone_w = 1200
        hero_phone_h = 1600  # 4:3
        title_size_hero = int(180 * (frame_w / 2580) * 1.25)
        eyebrow_font = 46
        sub_font = 50
        headline_top = 170
        phone_bottom_offset = 50  # 少し画面内に収める
        raw_dir_use = ipad_raw_dir

    print(f"\n=== {lang} / {device} ({frame_w}x{frame_h}) ===")

    # Hero 2-up
    left, right = render_hero_2up(
        texts, raw_dir_use,
        frame_w_each=frame_w, frame_h=frame_h,
        phone_w=hero_phone_w, phone_h=hero_phone_h,
        title_size=title_size_hero,
        eyebrow_font_size=eyebrow_font,
        sub_font_size=sub_font,
    )
    left.convert("RGB").save(out_dir / "01_hero_left.png", "PNG", optimize=True)
    right.convert("RGB").save(out_dir / "02_hero_right.png", "PNG", optimize=True)
    print(f"  01_hero_left.png / 02_hero_right.png")

    # Single frames
    configs = build_single_configs(texts, raw_dir_use)
    # iPad は title/eyebrow/sub を別倍率で上書き
    title_override = 152 if device == "ipad" else None
    eyebrow_override = eyebrow_font if device == "ipad" else None
    sub_override = sub_font if device == "ipad" else None
    for cfg in configs:
        img = render_single_frame(
            cfg, raw_dir_use,
            frame_size=(frame_w, frame_h),
            phone_size=(phone_w, phone_h),
            phone_bottom_offset=phone_bottom_offset,
            headline_top=headline_top,
            title_size_override=title_override,
            eyebrow_font_override=eyebrow_override,
            sub_font_override=sub_override,
        )
        img.convert("RGB").save(out_dir / f"{cfg.name}.png", "PNG", optimize=True)
        print(f"  {cfg.name}.png")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lang", choices=["ja", "en", "both"], default="both")
    ap.add_argument("--device", choices=["iphone", "ipad", "both"], default="both")
    ap.add_argument("--light", action="store_true",
                    help="raw_light/ipad_light を入力に使う (default は dark)")
    args = ap.parse_args()

    raw_iphone = RAW_LIGHT if args.light else RAW_DARK
    raw_ipad = IPAD_LIGHT if args.light else IPAD_DARK

    if not raw_iphone.exists():
        # フォールバック: 旧 dir (raw/)
        raw_iphone = PROJECT / "screenshots" / "raw"
        print(f"INFO: raw_iphone fallback to {raw_iphone}")
    if not raw_ipad.exists():
        raw_ipad = PROJECT / "screenshots" / "ipad"
        print(f"INFO: raw_ipad fallback to {raw_ipad}")

    langs = ["ja", "en"] if args.lang == "both" else [args.lang]
    devices = ["iphone", "ipad"] if args.device == "both" else [args.device]

    out_map = {
        ("ja", "iphone"): OUT_JA_67,
        ("ja", "ipad"): OUT_JA_IPAD,
        ("en", "iphone"): OUT_EN_67,
        ("en", "ipad"): OUT_EN_IPAD,
    }

    for lang in langs:
        for device in devices:
            render_all_for_device(
                lang=lang, device=device,
                raw_dir=raw_iphone, ipad_raw_dir=raw_ipad,
                out_dir=out_map[(lang, device)],
            )

    print("\n=== Done ===")
    for k, v in out_map.items():
        if v.exists():
            cnt = len(list(v.glob("*.png")))
            print(f"  {k[0]}/{k[1]}: {cnt} files at {v.relative_to(PROJECT)}")


if __name__ == "__main__":
    main()
