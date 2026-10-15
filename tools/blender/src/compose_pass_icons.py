import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ART = "/Users/wacko/Documents/growasyn/art/icons/passes/"
RAW = ART + "raw/"
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
NAVY = (36, 30, 90)
GOLDLINE = (255, 196, 40)
SIZE = 512
RADIUS = 78
OUTLINE = 17
STRIP = 92

SPEC = {
    "pass_double_income": dict(top=(255, 232, 130), bot=(255, 150, 60), label="2X MONEY", badge="x2"),
    "pass_patron": dict(top=(150, 175, 255), bot=(90, 90, 225), label="PATRON"),
    "pass_rapid_growth": dict(top=(175, 242, 150), bot=(60, 190, 110), label="RAPID GROWTH"),
    "pass_helping_hands": dict(top=(255, 205, 225), bot=(255, 130, 165), label="HELPING HANDS"),
    "pass_swift_delivery": dict(top=(150, 228, 255), bot=(60, 150, 240), label="SWIFT DELIVERY"),
    "pass_quick_merge": dict(top=(205, 175, 255), bot=(130, 90, 230), label="QUICK MERGE"),
    "pass_golden_wardrobe": dict(top=(150, 120, 225), bot=(80, 55, 160), label="GOLDEN WARDROBE", glow=True),
    "pass_pet_lover": dict(top=(255, 195, 215), bot=(240, 110, 150), label="PET LOVER"),
    "product_basket_s": dict(top=(195, 238, 255), bot=(100, 180, 240), label="SMALL BASKET", badge="S"),
    "product_basket_m": dict(top=(195, 246, 205), bot=(80, 200, 130), label="MEDIUM BASKET", badge="M"),
    "product_basket_l": dict(top=(255, 220, 155), bot=(255, 140, 70), label="LARGE BASKET", badge="L"),
    "product_growth_lamp": dict(top=(105, 70, 185), bot=(45, 30, 115), label="GROWTH LAMP", glow=True),
    "product_festival_boost": dict(top=(255, 160, 205), bot=(255, 105, 105), label="FESTIVAL BOOST"),
    "product_special_order": dict(top=(165, 222, 255), bot=(90, 150, 255), label="SPECIAL ORDER"),
    "product_complete_now": dict(top=(195, 255, 215), bot=(70, 200, 150), label="COMPLETE NOW"),
    "product_legacy_boost": dict(top=(50, 62, 145), bot=(22, 22, 75), label="LEGACY BOOST", glow=True),
    "product_special_pet": dict(top=(255, 228, 242), bot=(255, 170, 210), label="SPECIAL PET"),
    "product_cosmetic": dict(top=(205, 185, 255), bot=(250, 150, 220), label="COSMETIC"),
    "product_starter_pack": dict(top=(255, 215, 135), bot=(255, 140, 90), label="STARTER PACK"),
}


def font(px):
    try:
        return ImageFont.truetype(FONT, int(px))
    except Exception:
        return ImageFont.load_default()


def gradient(top, bot):
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        k = y / (SIZE - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * k) for i in range(3)) + (255,)
        for x in range(SIZE):
            px[x, y] = c
    return img


def rays(cx, cy, count=16, alpha=44):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    big = SIZE * 2
    for i in range(count):
        a0 = 2 * math.pi * i / count
        a1 = a0 + math.pi / count
        d.polygon([(cx, cy), (cx + math.cos(a0) * big, cy + math.sin(a0) * big), (cx + math.cos(a1) * big, cy + math.sin(a1) * big)], fill=(255, 255, 255, alpha))
    return layer.filter(ImageFilter.GaussianBlur(1.5))


def outlined(draw, xy, text, fnt, fill, outline, thickness, anchor="mm"):
    x, y = xy
    for dx in range(-thickness, thickness + 1):
        for dy in range(-thickness, thickness + 1):
            if dx * dx + dy * dy <= thickness * thickness:
                draw.text((x + dx, y + dy), text, font=fnt, fill=outline, anchor=anchor)
    draw.text((x, y), text, font=fnt, fill=fill, anchor=anchor)


def fit_font(draw, text, max_w, start):
    px = start
    while px > 16:
        f = font(px)
        if draw.textlength(text, font=f) <= max_w:
            return f
        px -= 2
    return font(16)


def starburst(cx, cy, radius, text):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = []
    spikes = 14
    for i in range(spikes * 2):
        a = math.pi * i / spikes - math.pi / 2
        r = radius if i % 2 == 0 else radius * 0.8
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(pts, fill=NAVY + (255,))
    d.polygon([(cx + (x - cx) * 0.93, cy + (y - cy) * 0.93) for x, y in pts], fill=(255, 120, 60, 255))
    d.polygon([(cx + (x - cx) * 0.8, cy + (y - cy) * 0.8) for x, y in pts], fill=(255, 196, 40, 255))
    outlined(d, (cx, cy + 2), text, font(radius * 0.8), (255, 255, 255), NAVY, max(2, int(radius * 0.06)))
    return layer.rotate(-8, resample=Image.BICUBIC, center=(cx, cy))


def letter_badge(cx, cy, radius, text):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=NAVY + (255,))
    d.ellipse([cx - radius * 0.88, cy - radius * 0.88, cx + radius * 0.88, cy + radius * 0.88], fill=(255, 140, 50, 255))
    d.ellipse([cx - radius * 0.7, cy - radius * 0.7, cx + radius * 0.7, cy + radius * 0.7], fill=(255, 196, 40, 255))
    outlined(d, (cx, cy + 3), text, font(radius * 1.15), (255, 255, 255), NAVY, max(2, int(radius * 0.07)))
    return layer


def compose(name, spec):
    raw = Image.open(RAW + name + ".png").convert("RGBA")
    bb = raw.getbbox()
    if bb:
        raw = raw.crop(bb)
    cy = (STRIP * -1 + SIZE) / 2 - 10
    base = gradient(spec["top"], spec["bot"])
    base.alpha_composite(rays(SIZE // 2, cy, 16, 40))
    if spec.get("glow"):
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([SIZE * 0.12, cy - 190, SIZE * 0.88, cy + 190], fill=(255, 238, 160, 150))
        base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(46)))
    else:
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([SIZE * 0.18, cy - 150, SIZE * 0.82, cy + 150], fill=(255, 255, 255, 80))
        base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(40)))
    maxw, maxh = 400, 340
    s = min(maxw / raw.width, maxh / raw.height)
    obj = raw.resize((max(1, int(raw.width * s)), max(1, int(raw.height * s))), Image.LANCZOS)
    ox = (SIZE - obj.width) // 2
    oy = int(cy - obj.height / 2) + 4
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sw = obj.width * 0.78
    by = oy + obj.height - 6
    sd.ellipse([SIZE / 2 - sw / 2, by - 12, SIZE / 2 + sw / 2, by + 20], fill=(20, 10, 60, 90))
    base.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))
    edge = Image.new("RGBA", obj.size, (0, 0, 0, 0))
    alpha = obj.getchannel("A")
    ring = alpha.filter(ImageFilter.MaxFilter(7))
    edge_px = Image.new("RGBA", obj.size, NAVY + (255,))
    edge.paste(edge_px, (0, 0), ring)
    base.alpha_composite(edge, (ox, oy))
    base.alpha_composite(obj, (ox, oy))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    y0 = SIZE - STRIP
    d.rectangle([0, y0, SIZE, SIZE], fill=NAVY + (255,))
    d.rectangle([0, y0, SIZE, y0 + 6], fill=GOLDLINE + (255,))
    f = fit_font(d, spec["label"], SIZE - 2 * (OUTLINE + 26), 46)
    ty = y0 + 6 + (STRIP - 6) // 2 - 2
    d.text((SIZE // 2, ty + 3), spec["label"], font=f, fill=(10, 8, 40, 200), anchor="mm")
    d.text((SIZE // 2, ty), spec["label"], font=f, fill=(255, 236, 120), anchor="mm")
    base.alpha_composite(layer)
    badge = spec.get("badge")
    if badge == "x2":
        base.alpha_composite(starburst(404, 106, 84, "x2"))
    elif badge:
        base.alpha_composite(letter_badge(96, 100, 58, badge))
    ss = 2
    mask = Image.new("L", (SIZE * ss, SIZE * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE * ss - 1, SIZE * ss - 1], radius=RADIUS * ss, fill=255)
    mask = mask.resize((SIZE, SIZE), Image.LANCZOS)
    base.putalpha(mask)
    hi = Image.new("RGBA", (SIZE * ss, SIZE * ss), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)
    hd.rounded_rectangle([OUTLINE * ss, OUTLINE * ss, SIZE * ss - OUTLINE * ss - 1, SIZE * ss - OUTLINE * ss - 1], radius=(RADIUS - OUTLINE) * ss, outline=(255, 255, 255, 90), width=4 * ss)
    base.alpha_composite(hi.resize((SIZE, SIZE), Image.LANCZOS))
    ol = Image.new("RGBA", (SIZE * ss, SIZE * ss), (0, 0, 0, 0))
    ImageDraw.Draw(ol).rounded_rectangle([0, 0, SIZE * ss - 1, SIZE * ss - 1], radius=RADIUS * ss, outline=NAVY + (255,), width=OUTLINE * ss)
    base.alpha_composite(ol.resize((SIZE, SIZE), Image.LANCZOS))
    base.save(ART + name + ".png")
    return base.size


if __name__ == "__main__":
    os.makedirs(ART, exist_ok=True)
    names = sys.argv[1:] or list(SPEC)
    for n in names:
        if os.path.exists(RAW + n + ".png"):
            compose(n, SPEC[n])
            print("ok", n)
        else:
            print("missing raw", n)
