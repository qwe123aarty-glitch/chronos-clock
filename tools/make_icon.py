#!/usr/bin/env python3
"""Render a 1024x1024 opaque app icon for Chronos."""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 2048          # supersampled canvas
OUT = 1024
CX = CY = S / 2
R = 726.0         # dial radius
ACCENT = (92, 220, 245)
ACCENT2 = (144, 116, 255)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


# ── background: vertical + radial depth ──────────────────────────────
small = 192
bg = Image.new("RGB", (small, small))
px = bg.load()
for y in range(small):
    for x in range(small):
        nx = (x / small - 0.5) * 2
        ny = (y / small - 0.5) * 2
        d = min(1.0, math.hypot(nx, ny * 0.85) / 1.42)
        top = (13, 24, 42)
        bottom = (5, 9, 17)
        base = lerp(top, bottom, (y / small) ** 0.75)
        shade = lerp((0, 0, 0), base, 1.0 - 0.45 * d)
        px[x, y] = shade

bg = bg.resize((S, S), Image.LANCZOS).convert("RGB")

# soft accent halo behind the dial
halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
hd.ellipse([CX - R * 1.05, CY - R * 1.05, CX + R * 1.05, CY + R * 1.05],
           fill=ACCENT + (34,))
halo = halo.filter(ImageFilter.GaussianBlur(110))
bg = Image.alpha_composite(bg.convert("RGBA"), halo).convert("RGB")

# ── dial plate ───────────────────────────────────────────────────────
plate = Image.new("RGBA", (S, S), (0, 0, 0, 0))
pd = ImageDraw.Draw(plate)
pd.ellipse([CX - R, CY - R, CX + R, CY + R], fill=(255, 255, 255, 12))
pd.ellipse([CX - R * 0.97, CY - R * 0.97, CX + R * 0.97, CY + R * 0.97],
           outline=(255, 255, 255, 26), width=4)
plate = plate.filter(ImageFilter.GaussianBlur(3))
bg = Image.alpha_composite(bg.convert("RGBA"), plate).convert("RGB")

# ── ring, drawn as 360 gradient arcs ─────────────────────────────────
ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
rd = ImageDraw.Draw(ring)
for i in range(360):
    t = i / 359.0
    c = lerp(ACCENT, ACCENT2, (math.sin(t * math.pi) ** 0.8))
    a = int(150 + 105 * math.sin(t * math.pi))
    rd.arc([CX - R, CY - R, CX + R, CY + R],
           start=-90 + i, end=-90 + i + 1.6,
           fill=c + (a,), width=7)
ring_glow = ring.filter(ImageFilter.GaussianBlur(26))
bg = Image.alpha_composite(bg.convert("RGBA"), ring_glow).convert("RGB")
bg = Image.alpha_composite(bg.convert("RGBA"), ring).convert("RGB")

# ── ticks ────────────────────────────────────────────────────────────
ticks = Image.new("RGBA", (S, S), (0, 0, 0, 0))
td = ImageDraw.Draw(ticks)
for i in range(60):
    major = i % 5 == 0
    a = math.radians(i * 6)
    outer = R - 26
    inner = outer - (78 if major else 30)
    x1, y1 = CX + math.sin(a) * inner, CY - math.cos(a) * inner
    x2, y2 = CX + math.sin(a) * outer, CY - math.cos(a) * outer
    if major:
        td.line([x1, y1, x2, y2], fill=(255, 255, 255, 205), width=11)
    else:
        td.line([x1, y1, x2, y2], fill=(255, 255, 255, 62), width=5)
bg = Image.alpha_composite(bg.convert("RGBA"), ticks).convert("RGB")


def hand_layer(angle_deg, length, width, color, blur=0, tail_ratio=0.055):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    a = math.radians(angle_deg)
    tail = tail_ratio * R
    x1, y1 = CX - math.sin(a) * tail, CY + math.cos(a) * tail
    x2, y2 = CX + math.sin(a) * length, CY - math.cos(a) * length
    d.line([x1, y1, x2, y2], fill=color, width=int(width))
    for (x, y) in ((x1, y1), (x2, y2)):
        d.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2],
                  fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur)) if blur else layer


# 10:10 的经典表盘角度；秒针单独指向 4 点半方向，避免与分针连成直线
hour_angle = (10 + 10 / 60) / 12 * 360      # 305°
minute_angle = 10 / 60 * 360                # 60°
second_angle = 26 / 60 * 360                # 156°

for ang, ln, w, col in [
    (hour_angle, R * 0.45, 44, (243, 246, 251, 252)),
    (minute_angle, R * 0.66, 30, (243, 246, 251, 252)),
]:
    bg = Image.alpha_composite(bg.convert("RGBA"), hand_layer(ang, ln, w, col)).convert("RGB")

# 秒针：先铺一层扩散辉光，再叠实线
bg = Image.alpha_composite(
    bg.convert("RGBA"),
    hand_layer(second_angle, R * 0.78, 40, ACCENT + (120,), blur=38)
).convert("RGB")
bg = Image.alpha_composite(
    bg.convert("RGBA"),
    hand_layer(second_angle, R * 0.78, 18, ACCENT + (190,), blur=12)
).convert("RGB")

sec = hand_layer(second_angle, R * 0.78, 13, ACCENT + (255,), tail_ratio=0.13)
bg = Image.alpha_composite(bg.convert("RGBA"), sec).convert("RGB")

# ── centre cap ───────────────────────────────────────────────────────
cap = Image.new("RGBA", (S, S), (0, 0, 0, 0))
cd = ImageDraw.Draw(cap)
cd.ellipse([CX - 40, CY - 40, CX + 40, CY + 40], fill=ACCENT + (255,))
cd.ellipse([CX - 16, CY - 16, CX + 16, CY + 16], fill=(10, 14, 22, 255))
bg = Image.alpha_composite(bg.convert("RGBA"), cap).convert("RGB")

# ── export ───────────────────────────────────────────────────────────
icon = bg.resize((OUT, OUT), Image.LANCZOS)
icon = icon.convert("RGB")
icon.save(r"D:/Newthings/chronos-clock/Chronos/Assets.xcassets/AppIcon.appiconset/icon-1024.png",
          "PNG", optimize=True)
print("wrote icon", icon.size, icon.mode)
