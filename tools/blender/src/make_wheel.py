import math
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
C = SIZE // 2
R = 480
INK = (30, 42, 74, 255)
SEGMENTS = [
    ("10 min", (86, 156, 255)),
    ("30 min", (94, 214, 130)),
    ("1 hour", (255, 154, 72)),
    ("Lamp", (255, 214, 80)),
    ("10 min", (86, 156, 255)),
    ("30 min", (94, 214, 130)),
    ("2 hours", (176, 124, 255)),
    ("Rare Item", (70, 214, 214)),
    ("10 min", (86, 156, 255)),
    ("Dew", (255, 61, 154)),
]
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse((C - R - 24, C - R - 24, C + R + 24, C + R + 24), fill=INK)
d.ellipse((C - R - 10, C - R - 10, C + R + 10, C + R + 10), fill=(255, 196, 40, 255))
n = len(SEGMENTS)
for i, (label, color) in enumerate(SEGMENTS):
    a0 = -90 + i * 360 / n
    a1 = -90 + (i + 1) * 360 / n
    shade = tuple(int(c * 0.8) for c in color)
    d.pieslice((C - R, C - R, C + R, C + R), a0, a1, fill=color + (255,), outline=INK, width=6)
    mid = math.radians((a0 + a1) / 2)
    inner = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    inner_d = ImageDraw.Draw(inner)
    pieslice_r = R * 0.62
    inner_d.pieslice((C - R * 0.99, C - R * 0.99, C + R * 0.99, C + R * 0.99), a0 + 1.2, a1 - 1.2, fill=(255, 255, 255, 38))
    img = Image.alpha_composite(img, inner)
    d = ImageDraw.Draw(img)

for i, (label, color) in enumerate(SEGMENTS):
    mid_deg = -90 + (i + 0.5) * 360 / n
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    size = 78 if len(label) <= 7 else 66
    font = ImageFont.truetype(FONT, size)
    bbox = ld.textbbox((0, 0), label, font=font, stroke_width=7)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    text_layer = Image.new("RGBA", (tw + 24, th + 24), (0, 0, 0, 0))
    td = ImageDraw.Draw(text_layer)
    td.text((12 - bbox[0], 12 - bbox[1]), label, font=font, fill=(255, 255, 255, 255), stroke_width=7, stroke_fill=INK)
    text_layer = text_layer.rotate(-mid_deg + 180 if False else -(mid_deg), expand=True, resample=Image.BICUBIC)
    r_text = R * 0.60
    cx = C + r_text * math.cos(math.radians(mid_deg))
    cy = C + r_text * math.sin(math.radians(mid_deg))
    img.alpha_composite(text_layer, (int(cx - text_layer.width / 2), int(cy - text_layer.height / 2)))

d = ImageDraw.Draw(img)
d.ellipse((C - 70, C - 70, C + 70, C + 70), fill=INK)
d.ellipse((C - 58, C - 58, C + 58, C + 58), fill=(255, 210, 63, 255))
d.ellipse((C - 38, C - 38, C + 38, C + 38), fill=(255, 244, 220, 255))
img.save("/Users/wacko/Documents/growasyn/art/icons/wheel_disc.png")
print("saved")
