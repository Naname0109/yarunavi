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


@dataclass
class SafeArea:
    """各フレームの描画可能領域 (これを跨いだ描画は禁止)。
    Hero 連結等で「テキストが境界を跨ぐ」 のを防ぐため、 全フレームで
    SafeArea 内に収まるように自動 fit する。
    """
    left: int = 80
    right: int = 80
    top: int = 120
    bottom: int = 100

    def text_width(self, frame_w: int) -> int:
        return frame_w - self.left - self.right


def fit_text_in_width(
    text: str,
    font_path: str,
    max_width: int,
    initial_size: int,
    *,
    min_size: int = 60,
) -> tuple[ImageFont.FreeTypeFont, int]:
    """テキストが max_width に収まる font + size を返す。
    initial_size から 2px ずつ縮小、 min_size まで。
    min_size でも収まらない場合は警告を print する (静かな overflow を防ぐ)。"""
    size = initial_size
    font = ImageFont.truetype(font_path, size)
    while size > min_size:
        bbox = font.getbbox(text)
        if (bbox[2] - bbox[0]) <= max_width:
            return font, size
        size -= 2
        font = ImageFont.truetype(font_path, size)
    # min_size でも収まらないケース: 警告 + そのまま返す
    bbox = font.getbbox(text)
    actual_w = bbox[2] - bbox[0]
    if actual_w > max_width:
        print(f"  WARN: fit_text_in_width overflow — "
              f"text={text!r} size={size} actual_w={actual_w} > max={max_width}")
    return font, size


def validate_frame(img: Image.Image, expected_w: int, expected_h: int,
                   name: str = "frame") -> None:
    """生成後の最小バリデーション。 NG なら AssertionError。"""
    w, h = img.size
    assert w == expected_w, f"{name}: width {w} != {expected_w}"
    assert h == expected_h, f"{name}: height {h} != {expected_h}"


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
        "title_l2_post": "が道筋を作る。",
        "sub": "書き出す → 優先順位を提案 → 迷わず動ける",
        "sub_left": "書き出す → AIが整理",
        "sub_right": "優先順位を提案 → 迷わず動ける",
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
        "sub_left": "Capture → AI sorts",
        "sub_right": "Prioritize → Act without doubt",
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


def _build_split_screen_raw(
    raw_left_path: Path, raw_right_path: Path, out_path: Path,
) -> Path:
    """ヒーロー用に「左半=ホーム、 右半=AI結果」 の合成 raw 画像を作る。
    両 raw は同サイズ前提 (1320x2868)。 中央で半分ずつクロップして連結。
    """
    a = Image.open(raw_left_path).convert("RGBA")
    b = Image.open(raw_right_path).convert("RGBA")
    if a.size != b.size:
        b = b.resize(a.size, Image.LANCZOS)
    w, h = a.size
    half = w // 2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    out.paste(a.crop((0, 0, half, h)), (0, 0))
    out.paste(b.crop((half, 0, w, h)), (half, 0))
    out.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


def _build_hero_shared_background(
    full_w: int, frame_h: int,
) -> Image.Image:
    """連結ヒーロー用の共有背景 (gradient + dots + 2 つの glow)。
    左右独立フレーム生成時に半分ずつ crop して使う。
    """
    canvas = draw_radial_bg(
        full_w, frame_h, center_pct=(0.5, 0.1), radius_pct=(1.20, 0.70),
        stops=[(0.0, (14, 24, 69)), (0.6, (5, 11, 34)), (1.0, (2, 5, 15))],
    )
    draw_dots(canvas, (255, 255, 255, 10))
    draw_glow(canvas, (0.35, 0.2), int(1300 * (full_w / 2580)),
              (125, 245, 237, 200))
    draw_glow(canvas, (0.70, 0.15), int(1100 * (full_w / 2580)),
              (180, 140, 255, 180))
    return canvas


def render_hero_combined(
    texts: dict, raw_dir: Path,
    *, frame_w: int, frame_h: int,
    phone_w: int, phone_h: int,
    title_size: int,
    eyebrow_font_size: int,
    sub_font_size: int,
    shared_bg: Image.Image,
) -> tuple[Image.Image, Image.Image]:
    """連結ヒーロー: フル幅 (2*frame_w) キャンバスに iPhone 1 台を中央配置し、
    左右テキストを描いてから 2 枚に分割して返す。"""
    h = texts["hero"]
    safe = SafeArea()
    full_w = frame_w * 2
    canvas = shared_bg.copy()

    # --- 共有 iPhone (raw 中央に「左=ホーム / 右=AI結果」 の合成画像) ---
    prefix = "ipad_" if raw_dir.name.startswith("ipad") else "raw_"
    raw_home = raw_dir / f"{prefix}01_home.png"
    raw_ai = raw_dir / f"{prefix}02_ai_result.png"
    py = frame_h - phone_h + int(-50 * (frame_h / 2796))
    phone_cx = full_w // 2
    px = phone_cx - phone_w // 2
    if raw_home.exists() and raw_ai.exists():
        tmp_split = raw_dir.parent / "_hero_split_screen_tmp.png"
        _build_split_screen_raw(raw_home, raw_ai, tmp_split)
        frame, _ = make_phone_frame(tmp_split, phone_w, phone_h,
                                     glow_color=(125, 245, 237))
        # 端末を境界中心にペースト
        paste_phone_with_glow(canvas, frame, px, py,
                              glow_color=(125, 245, 237))
        try:
            tmp_split.unlink()
        except OSError:
            pass

    # --- 左半分: アイブロウ + タイトル + サブ + ステップ1 ---
    cx_left = frame_w // 2
    eyebrow_y = safe.top + 20
    draw_eyebrow_badge(canvas, h["eyebrow_text"], cx_left, eyebrow_y,
                       (125, 245, 237), icon=h["eyebrow_icon"],
                       font_size=eyebrow_font_size)
    title_y = eyebrow_y + 90
    text_max = safe.text_width(frame_w)
    font_l, _ = fit_text_in_width(
        h["title_l1"], FONT_HEAVY, text_max, title_size, min_size=80)
    w1, _ = measure(h["title_l1"], font_l)
    d = ImageDraw.Draw(canvas)
    d.text((cx_left - w1 // 2, title_y), h["title_l1"],
           font=font_l, fill=(255, 255, 255, 255))
    sub_y = title_y + int(font_l.size * 1.18) + 20
    sub_font, _ = fit_text_in_width(
        h["sub_left"], FONT_SEMI, text_max, sub_font_size, min_size=22)
    draw_sub(canvas, h["sub_left"], cx_left, sub_y,
             color=(255, 255, 255, 165), size=sub_font.size)
    _draw_step_badge(canvas, h["step1_text"], h["step1_caption"],
                     px + 30, py - 100, (125, 245, 237))

    # --- 右半分: タイトル (AI accent) + サブ + ステップ2 ---
    cx_right = frame_w + frame_w // 2
    headline_y = safe.top + 90
    l2_pre = h["title_l2_pre"]
    l2_acc = h["title_l2_accent"]
    l2_post = h["title_l2_post"]
    full_text = f"{l2_pre}{l2_acc}{l2_post}"
    font_r, _ = fit_text_in_width(
        full_text, FONT_HEAVY, text_max, title_size, min_size=80)
    w_pre = measure(l2_pre, font_r)[0] if l2_pre else 0
    w_acc = measure(l2_acc, font_r)[0]
    w_post = measure(l2_post, font_r)[0]
    total = w_pre + w_acc + w_post
    x = cx_right - total // 2
    title_y_r = headline_y
    if l2_pre:
        d.text((x, title_y_r), l2_pre, font=font_r,
               fill=(255, 255, 255, 255))
        x += w_pre
    _draw_gradient_text(canvas, l2_acc, font_r, (x, title_y_r),
                        ((125, 245, 237), (180, 140, 255)))
    x += w_acc
    d.text((x, title_y_r), l2_post, font=font_r, fill=(255, 255, 255, 255))
    sub_y_r = title_y_r + int(font_r.size * 1.18) + 20
    sub_font_r, _ = fit_text_in_width(
        h["sub_right"], FONT_SEMI, text_max, sub_font_size, min_size=22)
    draw_sub(canvas, h["sub_right"], cx_right, sub_y_r,
             color=(255, 255, 255, 165), size=sub_font_r.size)
    _draw_step_badge(canvas, h["step2_text"], h["step2_caption"],
                     px + phone_w - 30, py - 100, (180, 140, 255),
                     align="right")

    # --- 2 枚に分割して返す ---
    left = canvas.crop((0, 0, frame_w, frame_h))
    right = canvas.crop((frame_w, 0, full_w, frame_h))
    validate_frame(left, frame_w, frame_h, name="hero_left")
    validate_frame(right, frame_w, frame_h, name="hero_right")
    return left, right


def render_hero_left(
    texts: dict, raw_dir: Path,
    *, frame_w: int, frame_h: int,
    phone_w: int, phone_h: int,
    title_size: int,
    eyebrow_font_size: int,
    sub_font_size: int,
    shared_bg_left: Image.Image,
    shared_phone_frame: Image.Image | None = None,
) -> Image.Image:
    """[非推奨] 旧シングルフレーム描画。 render_hero_combined を使う。"""
    h = texts["hero"]
    safe = SafeArea()
    canvas = shared_bg_left.copy()
    cx = frame_w // 2

    # アイブロウバッジ
    eyebrow_y = safe.top + 20
    draw_eyebrow_badge(canvas, h["eyebrow_text"], cx, eyebrow_y,
                       (125, 245, 237), icon=h["eyebrow_icon"],
                       font_size=eyebrow_font_size)

    # タイトル: 「登録するだけ。」
    title_y = eyebrow_y + 90
    text_max = safe.text_width(frame_w)
    font, _ = fit_text_in_width(
        h["title_l1"], FONT_HEAVY, text_max, title_size, min_size=80)
    w1, h1 = measure(h["title_l1"], font)
    d = ImageDraw.Draw(canvas)
    d.text((cx - w1 // 2, title_y), h["title_l1"],
           font=font, fill=(255, 255, 255, 255))

    # サブコピー (left 専用)
    sub_y = title_y + int(font.size * 1.18) + 20
    sub_font, _ = fit_text_in_width(
        h["sub_left"], FONT_SEMI, text_max, sub_font_size, min_size=22)
    draw_sub(canvas, h["sub_left"], cx, sub_y,
             color=(255, 255, 255, 165), size=sub_font.size)

    # 共有端末: フレーム境界 (右端) に中心が来るよう配置。
    # 左フレームから見ると phone の左半分だけが見える。
    py = frame_h - phone_h + int(-50 * (frame_h / 2796))
    global_phone_cx = frame_w  # 連結時の中心
    px_local = global_phone_cx - phone_w // 2  # 左フレーム内の paste 位置
    if shared_phone_frame is not None:
        paste_phone_with_glow(canvas, shared_phone_frame, px_local, py,
                              glow_color=(125, 245, 237))

    # ステップバッジ (見える半分の左寄せ)
    _draw_step_badge(canvas, h["step1_text"], h["step1_caption"],
                     px_local + 30, py - 100, (125, 245, 237))

    validate_frame(canvas, frame_w, frame_h, name="hero_left")
    return canvas


def render_hero_right(
    texts: dict, raw_dir: Path,
    *, frame_w: int, frame_h: int,
    phone_w: int, phone_h: int,
    title_size: int,
    eyebrow_font_size: int,
    sub_font_size: int,
    shared_bg_right: Image.Image,
    shared_phone_frame: Image.Image | None = None,
) -> Image.Image:
    """連結ヒーロー右半分。 共有 iPhone の右半分が見える形に変更。"""
    h = texts["hero"]
    safe = SafeArea()
    canvas = shared_bg_right.copy()
    cx = frame_w // 2

    # タイトル: pre + AI accent + post
    headline_y = safe.top + 90
    l2_pre = h["title_l2_pre"]
    l2_acc = h["title_l2_accent"]
    l2_post = h["title_l2_post"]
    full_text = f"{l2_pre}{l2_acc}{l2_post}"
    text_max = safe.text_width(frame_w)
    font, _ = fit_text_in_width(
        full_text, FONT_HEAVY, text_max, title_size, min_size=80)
    w_pre, _ = measure(l2_pre, font) if l2_pre else (0, 0)
    w_acc, _ = measure(l2_acc, font)
    w_post, _ = measure(l2_post, font)
    total = w_pre + w_acc + w_post
    x = cx - total // 2
    title_y = headline_y
    d = ImageDraw.Draw(canvas)
    if l2_pre:
        d.text((x, title_y), l2_pre, font=font, fill=(255, 255, 255, 255))
        x += w_pre
    _draw_gradient_text(canvas, l2_acc, font, (x, title_y),
                        ((125, 245, 237), (180, 140, 255)))
    x += w_acc
    d.text((x, title_y), l2_post, font=font, fill=(255, 255, 255, 255))

    # サブコピー (right 専用)
    sub_y = title_y + int(font.size * 1.18) + 20
    sub_font, _ = fit_text_in_width(
        h["sub_right"], FONT_SEMI, text_max, sub_font_size, min_size=22)
    draw_sub(canvas, h["sub_right"], cx, sub_y,
             color=(255, 255, 255, 165), size=sub_font.size)

    # 共有端末: 連結時のフレーム境界 (左端) に中心が来る。
    # 右フレームの座標系では phone 中心が x=0、 左半分は画面外。
    py = frame_h - phone_h + int(-50 * (frame_h / 2796))
    px_local = -(phone_w // 2)
    if shared_phone_frame is not None:
        paste_phone_with_glow(canvas, shared_phone_frame, px_local, py,
                              glow_color=(180, 140, 255))

    # ステップバッジ (見える半分の右寄せ)
    _draw_step_badge(canvas, h["step2_text"], h["step2_caption"],
                     px_local + phone_w - 30, py - 100, (180, 140, 255),
                     align="right")

    validate_frame(canvas, frame_w, frame_h, name="hero_right")
    return canvas


def _draw_arrow_half(
    canvas: Image.Image, edge_x: int, cy: int, size: int,
    *, grad: tuple[tuple[int, int, int], tuple[int, int, int]],
):
    """連結ヒーロー境界に半円の矢印 connector を描画。
    edge_x にフレーム端の x 座標を渡すと、 その位置を円中心として
    自動的にはみ出した側だけ canvas 内に描画される。
    左右フレームをつなげると 1 つの完全な円 + 矢印になる。
    """
    full = size
    # 円全体を別レイヤーに描き、 必要な半分だけ canvas に貼る
    layer = Image.new("RGBA", (full + 40, full + 40), (0, 0, 0, 0))
    arr = np.zeros((full, full, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:full, 0:full]
    inside = ((xx - full / 2) ** 2 + (yy - full / 2) ** 2) <= (full / 2) ** 2
    t = ((xx + yy) / (2 * full)).clip(0, 1)
    arr[..., 0] = (grad[0][0] * (1 - t) + grad[1][0] * t).astype(np.uint8)
    arr[..., 1] = (grad[0][1] * (1 - t) + grad[1][1] * t).astype(np.uint8)
    arr[..., 2] = (grad[0][2] * (1 - t) + grad[1][2] * t).astype(np.uint8)
    arr[..., 3] = (inside * 255).astype(np.uint8)
    circle = Image.fromarray(arr, "RGBA")
    layer.alpha_composite(circle, (20, 20))
    ld = ImageDraw.Draw(layer)
    ld.ellipse([20, 20, 20 + full, 20 + full],
               outline=(255, 255, 255, 70), width=4)
    # 矢印テキストは円中央に
    font = _font(FONT_HEAVY, int(full * 0.5))
    aw, ah = measure("→", font)
    ld.text((20 + full // 2 - aw // 2,
             20 + full // 2 - ah // 2 - int(full * 0.1)),
            "→", font=font, fill=(6, 36, 61, 255))

    # 円中心を canvas の境界に重ねるオフセットで貼る
    # paste 左上 = (edge_x - layer.width // 2, cy - layer.height // 2)
    canvas.alpha_composite(
        layer,
        (edge_x - layer.width // 2, cy - layer.height // 2),
    )


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
        eyebrow_font = 46
        sub_font = 50
        headline_top = 170
        phone_bottom_offset = 50  # 少し画面内に収める
        raw_dir_use = ipad_raw_dir

    print(f"\n=== {lang} / {device} ({frame_w}x{frame_h}) ===")

    # 連結ヒーロー (新仕様): フル幅で 1 つの iPhone を境界に置き、 2 枚に分割。
    full_w = frame_w * 2
    shared_bg = _build_hero_shared_background(full_w, frame_h)
    hero_title_size = 120 if device == "iphone" else 156
    left, right = render_hero_combined(
        texts, raw_dir_use,
        frame_w=frame_w, frame_h=frame_h,
        phone_w=hero_phone_w, phone_h=hero_phone_h,
        title_size=hero_title_size,
        eyebrow_font_size=eyebrow_font,
        sub_font_size=sub_font,
        shared_bg=shared_bg,
    )
    left.convert("RGB").save(out_dir / "01_hero_left.png", "PNG", optimize=True)
    right.convert("RGB").save(out_dir / "02_hero_right.png", "PNG", optimize=True)
    print("  01_hero_left.png / 02_hero_right.png")

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
