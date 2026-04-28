#!/usr/bin/env python3
"""YaruNavi app icon generator (1024x1024)

Design: blue gradient background + white checkmark + sparkle
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).parent.parent / "assets" / "icon" / "app_icon.png"


def draw_gradient(img):
    draw = ImageDraw.Draw(img)
    c1 = (80, 140, 255)   # top-left: bright blue
    c2 = (40, 80, 200)    # bottom-right: deep blue
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x / SIZE * 0.4 + y / SIZE * 0.6)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            draw.point((x, y), fill=(r, g, b))


def draw_gradient_fast(img):
    """Line-based gradient (much faster)."""
    draw = ImageDraw.Draw(img)
    c1 = (80, 145, 255)
    c2 = (35, 75, 195)
    for y in range(SIZE):
        t = y / SIZE
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))


def draw_checkmark(draw):
    """Thick rounded checkmark."""
    cx, cy = SIZE // 2, SIZE // 2 + 20
    pts = [
        (cx - 200, cy - 10),
        (cx - 60, cy + 150),
        (cx + 230, cy - 190),
    ]
    w = 72
    color = (255, 255, 255)
    draw.line([pts[0], pts[1]], fill=color, width=w, joint="curve")
    draw.line([pts[1], pts[2]], fill=color, width=w, joint="curve")
    for p in pts:
        draw.ellipse([p[0] - w // 2, p[1] - w // 2, p[0] + w // 2, p[1] + w // 2], fill=color)


def draw_sparkle(draw, cx, cy, size, color=(255, 255, 255)):
    """4-pointed star sparkle."""
    points = []
    n = 8
    for i in range(n):
        angle = math.pi * 2 * i / n - math.pi / 2
        r = size if i % 2 == 0 else size * 0.3
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=color)


def main():
    img = Image.new("RGB", (SIZE, SIZE))
    draw_gradient_fast(img)

    # Subtle radial glow at center
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([SIZE // 4, SIZE // 4, SIZE * 3 // 4, SIZE * 3 // 4],
               fill=(255, 255, 255, 25))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=120))
    img.paste(Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB"))

    draw = ImageDraw.Draw(img)
    draw_checkmark(draw)

    # Main sparkle (top-right of checkmark)
    draw_sparkle(draw, 710, 280, 44)
    # Small sparkle
    draw_sparkle(draw, 620, 220, 22)
    # Tiny sparkle
    draw_sparkle(draw, 770, 350, 14)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Icon saved: {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
