import math
import random
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = "/Users/wacko/Documents/growasyn/"
ICONS = ROOT + "art/icons/"
OUT = ROOT + "docs/store/"
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"


def sky(w, h, horizon):
    img = Image.new("RGBA", (w, h))
    px = img.load()
    top = (64, 156, 255)
    mid = (140, 210, 255)
    low = (255, 240, 200)
    for y in range(h):
        t = min(y / max(horizon, 1), 1.0)
        if t < 0.6:
            k = t / 0.6
            c = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.6) / 0.4
            c = tuple(int(mid[i] + (low[i] - mid[i]) * k) for i in range(3))
        for x in range(w):
            px[x, y] = c + (255,)
    return img


def rays(w, h, cx, cy, count=18, alpha=46):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    big = max(w, h) * 2
    for i in range(count):
        a0 = 2 * math.pi * i / count
        a1 = a0 + math.pi / count
        d.polygon([(cx, cy), (cx + math.cos(a0) * big, cy + math.sin(a0) * big), (cx + math.cos(a1) * big, cy + math.sin(a1) * big)], fill=(255, 255, 255, alpha))
    return layer.filter(ImageFilter.GaussianBlur(2))


def clouds(w, h, seed=7, count=7):
    rnd = random.Random(seed)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x = rnd.randint(0, w)
        y = rnd.randint(int(h * 0.05), int(h * 0.3))
        s = rnd.randint(int(h * 0.05), int(h * 0.09))
        for dx, dy, r in ((0, 0, s), (-s, s * 0.3, s * 0.75), (s, s * 0.3, s * 0.8), (s * 2, s * 0.45, s * 0.6), (-s * 1.9, s * 0.5, s * 0.55)):
            d.ellipse([x + dx - r, y + dy - r * 0.8, x + dx + r, y + dy + r * 0.8], fill=(255, 255, 255, 235))
    return layer.filter(ImageFilter.GaussianBlur(1.5))


def outlined(draw, xy, text, font, fill, outline, thickness, anchor="mm"):
    x, y = xy
    for dx in range(-thickness, thickness + 1):
        for dy in range(-thickness, thickness + 1):
            if dx * dx + dy * dy <= thickness * thickness:
                draw.text((x + dx, y + dy), text, font=font, fill=outline, anchor=anchor)
    draw.text((x, y), text, font=font, fill=fill, anchor=anchor)


def title_block(img, cx, cy, size, tilt=0.0):
    w, h = img.size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    f1 = ImageFont.truetype(FONT, int(size))
    f2 = ImageFont.truetype(FONT, int(size * 0.62))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    outlined(sd, (cx + size * 0.05, cy + size * 0.09), "GROW A", f1, (20, 20, 50, 160), (20, 20, 50, 160), int(size * 0.13))
    outlined(sd, (cx + size * 0.05, cy + size * 0.09 + size * 0.88), "SYNAGOGUE", f2, (20, 20, 50, 160), (20, 20, 50, 160), int(size * 0.1))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(size * 0.03)))
    outlined(d, (cx, cy), "GROW A", f1, (255, 236, 120), (36, 30, 90), int(size * 0.095))
    outlined(d, (cx, cy + size * 0.88), "SYNAGOGUE", f2, (255, 255, 255), (36, 30, 90), int(size * 0.075))
    if tilt:
        layer = layer.rotate(tilt, resample=Image.BICUBIC, center=(cx, cy))
    img.alpha_composite(layer)


def callout(img, cx, cy, radius, text, sub):
    w, h = img.size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    points = []
    spikes = 14
    for i in range(spikes * 2):
        a = math.pi * i / spikes - math.pi / 2
        r = radius if i % 2 == 0 else radius * 0.8
        points.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(points, fill=(36, 30, 90, 255))
    inner = [(cx + (x - cx) * 0.93, cy + (y - cy) * 0.93) for x, y in points]
    d.polygon(inner, fill=(255, 120, 60, 255))
    inner2 = [(cx + (x - cx) * 0.8, cy + (y - cy) * 0.8) for x, y in points]
    d.polygon(inner2, fill=(255, 196, 40, 255))
    f1 = ImageFont.truetype(FONT, int(radius * 0.52))
    f2 = ImageFont.truetype(FONT, int(radius * 0.26))
    outlined(d, (cx, cy - radius * 0.1), text, f1, (255, 255, 255), (36, 30, 90), int(radius * 0.045))
    outlined(d, (cx, cy + radius * 0.34), sub, f2, (255, 255, 255), (36, 30, 90), int(radius * 0.03))
    layer = layer.rotate(-8, resample=Image.BICUBIC, center=(cx, cy))
    img.alpha_composite(layer)


def thumbnail():
    scene = Image.open(ICONS + "thumb_scene.png").convert("RGBA")
    w, h = scene.size
    base = sky(w, h, 560)
    base.alpha_composite(rays(w, h, w // 2, 520, 22, 40))
    base.alpha_composite(clouds(w, h))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([w * 0.3, h * 0.12, w * 0.7, h * 0.7], fill=(255, 245, 200, 130))
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))
    base.alpha_composite(scene)
    title_block(base, w * 0.5, 118, 150)
    callout(base, w * 0.865, h * 0.30, 168, "x2", "MONEY")
    out = base.convert("RGB")
    out.save(OUT + "thumbnail_1920x1080.png")
    out.resize((1280, 720), Image.LANCZOS).save(OUT + "thumbnail_1280x720.png")
    return out.size


def icon():
    scene = Image.open(ICONS + "icon_scene.png").convert("RGBA")
    w, h = scene.size
    base = sky(w, h, 640)
    base.alpha_composite(rays(w, h, w // 2, 560, 18, 44))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([w * 0.2, h * 0.1, w * 0.8, h * 0.75], fill=(255, 245, 200, 140))
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(70)))
    base.alpha_composite(scene)
    title_block(base, w * 0.5, 120, 120)
    out = base.convert("RGB")
    out.save(OUT + "icon_1024.png")
    out.resize((512, 512), Image.LANCZOS).save(OUT + "icon_512.png")
    return out.size


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    if which in ("thumb", "all"):
        print("thumbnail", thumbnail())
    if which in ("icon", "all"):
        print("icon", icon())
