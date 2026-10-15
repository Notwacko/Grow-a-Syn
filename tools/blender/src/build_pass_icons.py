K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())
import random
import subprocess

GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
BLUE, BLUE_D, SKY = "3B72E0", "1E3E96", "3FA7FF"
RED, GREEN, GREEN_D, LIME = "E8453C", "5FD068", "2E9E45", "7BE06A"
WOOD, WOOD_L, WOOD_D = "9A5E33", "C98B52", "6B3E22"
CREAM, WHITE, NAVY = "FFF1D0", "FFFFFF", "26396E"
PINK, PURPLE, ORANGE = "FF7FAE", "8E5BE0", "FF9A3C"
SKIN = "F6C79B"
EYE, SHINE = "23233A", "FFFFFF"
METAL = dict(metal=0.6, rough=0.3)
OUT = ICONS + "/passes"
RAW = OUT + "/raw"


def edeg(M):
    e = M.to_euler('XYZ')
    return (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z))


def align_z(pos, normal, spin=0.0):
    q = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized())
    M = q.to_matrix().to_4x4()
    if spin:
        M = M @ Matrix.Rotation(math.radians(spin), 4, 'Z')
    return Matrix.Translation(Vector(pos)) @ M


def E(t, label, hexs, c, rad, rot=(0, 0, 0), u=None, v=None, **kw):
    if u is None:
        big = max(rad)
        u, v = (20, 12) if big >= 0.7 else ((14, 9) if big >= 0.3 else (10, 6))
    t.sphere(label, hexs, c, 1.0, u=u, v=v, scale=rad, rot=rot, **kw)


def shape(t, label, hexs, pts, thick, c=(0, 0, 0), bevel=0.08, **kw):
    t.poly(label, hexs, [(x + c[0], z + c[2]) for x, z in pts], c[1] - thick / 2, c[1] + thick / 2, bevel=bevel, plane="XZ", **kw)


def scaled(pts, sx, sz=None):
    sz = sx if sz is None else sz
    return [(x * sx, z * sz) for x, z in pts]


def star5(r, inner=0.46):
    out = []
    for k in range(10):
        a = math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * inner
        out.append((math.cos(a) * rr, math.sin(a) * rr))
    return out


def sparkle(r, w=0.24):
    return [(0, r), (r * w, r * w), (r, 0), (r * w, -r * w), (0, -r), (-r * w, -r * w), (-r, 0), (-r * w, r * w)]


def heart(s):
    out = []
    n = 44
    for i in range(n):
        a = 2 * math.pi * i / n
        x = 16 * math.sin(a) ** 3
        y = 13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)
        out.append((x * s, (y + 2) * s))
    return out


def ring_band(t, label, hexs, c, rin, rout, h, seg=28, ch=0.02, rot=(0, 0, 0), **kw):
    prof = [(rin, 0), (rout - ch, 0), (rout, ch), (rout, h - ch), (rout - ch, h), (rin, h), (rin, 0)]
    t.lathe(label, hexs, c, prof, seg=seg, rot=rot, **kw)


def coin(t, c, r=0.85, h=0.2, rot=(0, 0, 0), emblem=False):
    t.cyl("Coin", GOLD, c, r, h, seg=28, rot=rot, bevel=0.04, metal=0.55, rough=0.28)
    if emblem:
        M0 = xf(c, rot)
        top = M0 @ Vector((0, 0, h / 2))
        t.torus("CoinRim", GOLD_L, (top.x, top.y, top.z), r * 0.76, r * 0.05, seg=26, rseg=5, rot=rot, metal=0.5, rough=0.3)
        M = M0 @ Matrix.Translation((0, 0, h / 2 + 0.005))
        for flip in (1, -1):
            pts = [(0, r * 0.42 * flip), (-r * 0.364, -r * 0.21 * flip), (r * 0.364, -r * 0.21 * flip)]
            bm = t.bm("CoinStar", GOLD_D, metal=0.5, rough=0.3)
            a = [bm.verts.new(M @ Vector((x, y, -0.03))) for x, y in pts]
            b = [bm.verts.new(M @ Vector((x, y, 0.03))) for x, y in pts]
            bm.faces.new(a)
            bm.faces.new(list(reversed(b)))
            for i in range(3):
                j = (i + 1) % 3
                bm.faces.new((a[i], a[j], b[j], b[i]))


def hanger(t, hexs, label="Hanger", r=0.1):
    kw = dict(metal=0.75, rough=0.25)
    hook = [(0, 0, 0.75), (0, 0, 1.18)]
    for k in range(0, 10):
        a = math.radians(-90 + k * 30)
        hook.append((0.32 * math.cos(a), 0, 1.5 + 0.32 * math.sin(a)))
    tube(t, label, hexs, hook, r, seg=10, **kw)
    loop = [(-1.9, 0, -0.35), (0, 0, 0.75), (1.9, 0, -0.35), (-1.9, 0, -0.35)]
    tube(t, label, hexs, loop, r, seg=10, **kw)
    t.sphere(label, hexs, (-1.9, 0, -0.35), r, u=10, v=6, **kw)


def ic_double_income():
    t = Toy("i", rough=0.4)
    rnd = random.Random(2)
    for (x, y, n) in ((0.0, 0.2, 8), (1.85, 0.7, 5), (-1.85, 0.6, 4)):
        for i in range(n):
            j = rnd.uniform(-0.05, 0.05)
            coin(t, (x + j, y + j, 0.1 + i * 0.22), 0.85, emblem=(i == n - 1))
    coin(t, (0.55, -1.5, 0.88), 0.85, rot=(75, 0, 25), emblem=True)
    coin(t, (-1.0, -1.35, 0.1), 0.85, emblem=True)
    return t


def crown(t, c, s=1.0):
    gold = dict(metal=0.6, rough=0.3)
    x0, y0, z0 = c
    ring_band(t, "Crown", GOLD, (x0, y0, z0), 0.62 * s, 0.76 * s, 0.4 * s, seg=28, **gold)
    t.torus("CrownTrim", GOLD_L, (x0, y0, z0 + 0.02 * s), 0.76 * s, 0.05 * s, seg=28, rseg=5, **gold)
    t.torus("CrownTrim", GOLD_L, (x0, y0, z0 + 0.38 * s), 0.76 * s, 0.05 * s, seg=28, rseg=5, **gold)
    cols = [RED, SKY, WHITE]
    for k in range(5):
        a = 2 * math.pi * k / 5 - math.pi / 2
        x, y = x0 + math.cos(a) * 0.72 * s, y0 + math.sin(a) * 0.72 * s
        t.cyl("Crown", GOLD, (x, y, z0 + 0.7 * s), 0.17 * s, 0.6 * s, seg=10, r2=0.04 * s, **gold)
        t.sphere("Gem", cols[k % 3], (x, y, z0 + 1.05 * s), 0.12 * s, u=12, v=8, rough=0.15)
        a2 = a + math.pi / 5
        t.sphere("Gem", cols[(k + 1) % 3], (x0 + math.cos(a2) * 0.79 * s, y0 + math.sin(a2) * 0.79 * s, z0 + 0.2 * s), 0.1 * s, u=10, v=6, rough=0.15)


def ic_patron():
    t = Toy("i", rough=0.45)
    banner = [(-1.2, 1.5), (1.2, 1.5), (1.2, -1.5), (0.0, -0.95), (-1.2, -1.5)]
    shape(t, "Trim", GOLD, scaled(banner, 1.1), 0.2, (0, 0.05, 0), bevel=0.07, **METAL)
    shape(t, "Banner", BLUE, scaled(banner, 0.94), 0.3, (0, -0.02, -0.02), bevel=0.08)
    shape(t, "Trim", GOLD_L, scaled(banner, 0.78), 0.1, (0, -0.2, -0.06), bevel=0.02, **METAL)
    shape(t, "Banner", BLUE_D, scaled(banner, 0.72), 0.1, (0, -0.24, -0.06), bevel=0.02)
    star6(t, "Star", GOLD, (0, -0.34, 0.15), 0.62, 0.1)
    t.cyl("Trim", GOLD, (0, 0, 1.78), 0.1, 3.3, seg=12, rot=(0, 90, 0), **METAL)
    for sx in (-1, 1):
        t.sphere("Trim", GOLD_L, (sx * 1.68, 0, 1.78), 0.2, u=14, v=9, **METAL)
    crown(t, (0, 0, 1.98), 1.15)
    return t


def ic_rapid_growth():
    t = Toy("i", rough=0.45)
    t.lathe("Pot", "E0794A", (0, 0, 0), [(0, 0), (0.62, 0), (0.92, 1.0)], seg=32)
    ring_band(t, "PotRim", "F08A5A", (0, 0, 1.0), 0.8, 1.12, 0.32, seg=32, ch=0.05)
    t.cyl("Soil", "5A3A22", (0, 0, 1.22), 0.95, 0.1, seg=28)
    star6(t, "PotStar", CREAM, (0, -0.83, 0.5), 0.3, 0.08)
    tube(t, "Stem", GREEN_D, [(0, 0, 1.2), (0.05, 0, 1.9), (0, 0, 2.6), (-0.08, 0, 3.2)], 0.12, seg=10)
    E(t, "Leaf", GREEN, (-0.8, 0, 2.35), (0.8, 0.1, 0.4), rot=(0, 22, 0))
    E(t, "Leaf", GREEN, (0.85, 0, 2.95), (0.85, 0.1, 0.42), rot=(0, -22, 0))
    E(t, "Leaf", LIME, (-0.5, 0, 3.55), (0.55, 0.09, 0.3), rot=(0, 28, 0))
    E(t, "Leaf", LIME, (0.4, 0, 3.7), (0.5, 0.09, 0.28), rot=(0, -28, 0))
    ar = [(0, 1), (0.62, 0.25), (0.25, 0.25), (0.25, -1), (-0.25, -1), (-0.25, 0.25), (-0.62, 0.25)]
    shape(t, "Arrow", LIME, scaled(ar, 0.9), 0.3, (2.3, 0, 1.5))
    shape(t, "Arrow", GOLD, scaled(ar, 0.62), 0.3, (2.95, 0, 3.0), **METAL)
    shape(t, "Arrow", LIME, scaled(ar, 0.5), 0.3, (-2.5, 0, 3.1))
    return t


def hand(t, sx):
    x = sx * 0.78
    E(t, "Skin", SKIN, (x, 0, 0), (0.52, 0.55, 0.2))
    for k, dx in enumerate((-0.33, -0.11, 0.11, 0.33)):
        ln = 0.95 if k in (1, 2) else 0.8
        pts = [(x + dx, -0.45, 0.04), (x + dx, -0.45 - ln * 0.6, 0.18), (x + dx, -0.45 - ln * 0.95, 0.55)]
        tube(t, "Skin", SKIN, pts, 0.1, seg=10)
        t.sphere("Skin", SKIN, pts[-1], 0.1, u=12, v=8)
        t.sphere("Skin", SKIN, pts[0], 0.1, u=12, v=8)
    tube(t, "Skin", SKIN, [(sx * 0.38, -0.05, 0.12), (sx * 0.22, -0.55, 0.28)], 0.13, seg=10)
    t.sphere("Skin", SKIN, (sx * 0.22, -0.55, 0.28), 0.13, u=12, v=8)
    t.cyl("Cuff", BLUE, (x, 0.7, 0.0), 0.46, 0.6, seg=20, rot=(90, 0, 0), bevel=0.04)
    t.torus("CuffTrim", WHITE, (x, 0.4, 0.0), 0.47, 0.06, seg=20, rseg=6, rot=(90, 0, 0))


def ic_helping_hands():
    t = Toy("i", rough=0.5)
    hand(t, -1)
    hand(t, 1)
    coin(t, (0, 0.3, 1.45), 0.98, 0.26, rot=(90, 0, 0), emblem=True)
    shape(t, "Sparkle", GOLD_L, sparkle(0.35), 0.1, (-1.2, -0.3, 2.3), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (1.3, -0.3, 2.5), bevel=0.02)
    return t


def clock(t, c, r=1.0):
    x0, y0, z0 = c
    t.cyl("ClockBody", RED, (x0, y0, z0), r, 0.55, seg=32, rot=(90, 0, 0), bevel=0.08)
    t.cyl("ClockFace", WHITE, (x0, y0 - 0.3, z0), r * 0.82, 0.1, seg=32, rot=(90, 0, 0))
    for k in range(12):
        a = math.radians(k * 30)
        t.box("Tick", NAVY, (x0 + math.sin(a) * r * 0.68, y0 - 0.38, z0 + math.cos(a) * r * 0.68), (0.08, 0.04, 0.18 if k % 3 == 0 else 0.1), rot=(0, k * 30, 0), bevel=0.0)
    for ang, ln in ((30, 0.62), (-70, 0.44)):
        a = math.radians(ang)
        t.box("Hand", NAVY, (x0 + math.sin(a) * ln / 2, y0 - 0.42, z0 + math.cos(a) * ln / 2), (0.1, 0.05, ln), rot=(0, ang, 0), bevel=0.02)
    t.sphere("Pin", GOLD, (x0, y0 - 0.46, z0), 0.09, u=10, v=6)
    for sx in (-1, 1):
        t.sphere("Bell", GOLD, (x0 + sx * 0.62, y0, z0 + r * 0.92), 0.3, u=14, v=9, scale=(1, 0.8, 0.8), **METAL)
        t.cyl("Foot", NAVY, (x0 + sx * 0.6, y0, z0 - r * 1.0), 0.1, 0.3, seg=10, rot=(0, sx * 25, 0))
    t.cyl("Hammer", NAVY, (x0, y0, z0 + r * 1.05), 0.05, 0.25, seg=8)


def ic_swift_delivery():
    t = Toy("i", rough=0.5)
    t.box("Crate", WOOD, (1.2, 0.2, 0.9), (2.5, 2.1, 1.8), bevel=0.14)
    for z in (0.4, 0.9, 1.4):
        t.box("Slat", WOOD_L, (1.2, -0.88, z), (2.2, 0.08, 0.34), bevel=0.04)
    t.box("Ribbon", BLUE, (1.2, -0.93, 0.9), (0.4, 0.06, 1.82), bevel=0.02)
    star6(t, "Star", GOLD, (1.2, -1.0, 0.95), 0.42, 0.07)
    t.box("Ribbon", BLUE, (1.2, 0.2, 1.84), (0.4, 2.12, 0.1), bevel=0.02)
    clock(t, (-1.1, -1.1, 1.65), 0.95)
    for (x, z, ln) in ((-3.0, 0.5, 1.6), (-3.4, 1.3, 1.2), (-3.1, 2.1, 1.5)):
        t.box("Speed", SKY, (x, 0.3, z), (ln, 0.12, 0.16), bevel=0.05)
    return t


def ic_quick_merge():
    t = Toy("i", rough=0.4)
    t.box("Cube", RED, (-2.5, -0.2, 0.5), (1.0, 1.0, 1.0), bevel=0.14, rot=(0, 0, 8))
    t.box("Cube", BLUE, (-1.2, -0.2, 0.5), (1.0, 1.0, 1.0), bevel=0.14, rot=(0, 0, -6))
    t.box("Cube", GOLD, (-1.85, -0.2, 1.55), (1.0, 1.0, 1.0), bevel=0.14, rot=(0, 0, 4))
    t.box("BigCube", GREEN, (2.0, 0, 1.15), (2.3, 2.3, 2.3), bevel=0.3)
    star6(t, "Star", GOLD_L, (2.0, -1.2, 1.2), 0.62, 0.1)
    ar = [(-0.5, 0.22), (0.05, 0.22), (0.05, 0.6), (0.75, 0), (0.05, -0.6), (0.05, -0.22), (-0.5, -0.22)]
    shape(t, "Arrow", GOLD, scaled(ar, 1.0), 0.28, (-0.15, -1.2, 1.5), **METAL)
    shape(t, "Sparkle", GOLD_L, sparkle(0.3), 0.1, (0.6, -1.3, 2.9), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.22), 0.1, (3.6, -1.3, 2.6), bevel=0.02)
    return t


def ic_golden_wardrobe():
    t = Toy("i", rough=0.45)
    hanger(t, GOLD, r=0.13)
    cape = [(-0.9, -0.5), (0.9, -0.5), (1.3, -1.2), (2.1, -2.75), (1.2, -3.0), (0.0, -2.75), (-1.2, -3.0), (-2.1, -2.75), (-1.3, -1.2)]
    shape(t, "Trim", GOLD, [(x * 1.09, -1.75 + (z + 1.75) * 1.09) for x, z in cape], 0.2, (0, 0.12, 0), bevel=0.05, **METAL)
    shape(t, "Cape", BLUE, cape, 0.3, (0, 0.0, 0.0), bevel=0.07)
    for fx, ang in ((-0.7, 7), (0.0, 0), (0.7, -7)):
        t.box("Fold", "2F55C0", (fx * 1.25, -0.17, -1.9), (0.14, 0.05, 1.9), bevel=0.0, rot=(0, ang, 0))
    t.cyl("Trim", GOLD, (0, -0.2, -0.66), 0.22, 0.1, seg=18, rot=(90, 0, 0), **METAL)
    t.sphere("Gem", RED, (0, -0.28, -0.66), 0.11, u=12, v=8, rough=0.15)
    kx = -1.15
    dome(t, "Kippah", "FFF4DC", (kx, 0, -0.26), 0.9, 0.5, seg=28, steps=5)
    for i, hx in enumerate(("FF6B6B", "FFA94D", "FFE066", "69DB7C", "4DABF7")):
        a = math.radians(6 + i * 17)
        t.torus("KipRing", hx, (kx, 0, -0.26 + 0.5 * math.sin(a)), 0.9 * math.cos(a) + 0.012, 0.07, seg=28, rseg=5)
    t.sphere("Kippah", "FF6B9A", (kx, 0, 0.27), 0.12, u=10, v=6)
    shape(t, "Sparkle", GOLD_L, sparkle(0.35), 0.1, (2.2, -0.3, 1.2), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (-2.3, -0.3, 1.5), bevel=0.02)
    return t


def ic_pet_lover():
    t = Toy("i", rough=0.4)
    shape(t, "Heart", "F0457A", heart(0.1), 0.9, (0, 0.2, 0.6), bevel=0.2)
    shape(t, "Heart", "FF7FA8", scaled(heart(0.1), 0.78), 0.1, (0.0, -0.3, 0.5), bevel=0.02)
    pad = (-0.05, -0.43, 0.3)
    E(t, "Paw", WHITE, pad, (0.42, 0.1, 0.34), u=16, v=10)
    for dx, dz in ((-0.62, 0.55), (-0.2, 0.85), (0.22, 0.85), (0.64, 0.55)):
        E(t, "Paw", WHITE, (pad[0] + dx, pad[1], pad[2] + dz), (0.16, 0.1, 0.2), u=12, v=8)
    cx, cy, cz = 1.7, -1.0, -0.95
    ORG, DARK = "F29A3C", "C96A1A"
    E(t, "CatFur", ORG, (cx, cy, cz), (0.9, 0.8, 0.76))
    for sx in (-1, 1):
        t.cyl("CatFur", ORG, (cx + sx * 0.58, cy, cz + 0.72), 0.3, 0.55, seg=12, r2=0.03, rot=(0, sx * 18, 0), scale=(1, 0.6, 1))
        t.cyl("CatInner", "FFB3C0", (cx + sx * 0.56, cy - 0.08, cz + 0.68), 0.18, 0.4, seg=12, r2=0.02, rot=(0, sx * 18, 0), scale=(1, 0.4, 1))
        E(t, "CatEye", EYE, (cx + sx * 0.34, cy - 0.7, cz + 0.08), (0.14, 0.09, 0.2), u=12, v=8)
        E(t, "CatShine", SHINE, (cx + sx * 0.34 - 0.04, cy - 0.77, cz + 0.16), (0.05, 0.03, 0.06), u=8, v=5)
        E(t, "CatCheek", "FF9AA2", (cx + sx * 0.6, cy - 0.58, cz - 0.15), (0.16, 0.05, 0.1), u=10, v=6)
        for k in (-1, 0, 1):
            tube(t, "Whisker", WHITE, [(cx + sx * 0.5, cy - 0.66, cz - 0.1), (cx + sx * 1.15, cy - 0.7, cz - 0.08 + k * 0.14)], 0.018, seg=4, joints=False)
    E(t, "CatNose", "FF8FA3", (cx, cy - 0.78, cz - 0.1), (0.1, 0.07, 0.07), u=10, v=6)
    tube(t, "CatMouth", "8A3B3B", [(cx - 0.18, cy - 0.74, cz - 0.28), (cx - 0.08, cy - 0.77, cz - 0.33), (cx, cy - 0.77, cz - 0.2), (cx + 0.08, cy - 0.77, cz - 0.33), (cx + 0.18, cy - 0.74, cz - 0.28)], 0.025, seg=5, joints=False)
    E(t, "CatFur", ORG, (cx, cy + 0.1, cz - 0.9), (0.75, 0.65, 0.5))
    t.torus("Accent", SKY, (cx, cy + 0.1, cz - 0.55), 0.62, 0.07, seg=22, rseg=5, metal=0.2, rough=0.2)
    return t


def basket(t):
    t.lathe("Wicker", "D9A85C", (0, 0, 0), [(0, 0), (0.9, 0), (1.15, 0.2), (1.5, 1.2), (1.38, 1.2), (1.08, 0.3), (0, 0.26)], seg=36)
    for z in (0.45, 0.72, 0.98):
        rr = 1.15 + 0.35 * (z - 0.2) / 1.0 + 0.015
        t.torus("Weave", "B07F3A", (0, 0, z), rr, 0.05, seg=36, rseg=5)
    t.torus("Weave", "B07F3A", (0, 0, 1.2), 1.44, 0.1, seg=36, rseg=6)


def pile(t, layers, seed, r=0.44):
    rnd = random.Random(seed)
    for z, rad, n, tilt in layers:
        for i in range(n):
            a = 2 * math.pi * i / max(n, 1) + rnd.uniform(-0.2, 0.2)
            pos = (rad * math.cos(a), rad * math.sin(a), z + rnd.uniform(-0.04, 0.04))
            tl = math.radians(tilt + rnd.uniform(-6, 6))
            nrm = (math.cos(a) * math.sin(tl), math.sin(a) * math.sin(tl) - 0.1, math.cos(tl))
            M = align_z(pos, nrm, spin=rnd.uniform(0, 90))
            t.cyl("Coin", GOLD, pos, r, 0.12, seg=22, rot=edeg(M), bevel=0.03, metal=0.55, rough=0.28)


def ic_basket(level):
    t = Toy("i", rough=0.5)
    basket(t)
    if level == "s":
        pile(t, [(1.1, 0.62, 5, 22), (1.28, 0.0, 1, 0)], 3)
        coin(t, (1.95, -0.9, 0.1), 0.5, 0.12, emblem=False)
    elif level == "m":
        pile(t, [(1.12, 0.95, 9, 26), (1.4, 0.52, 5, 18), (1.62, 0.0, 1, 0)], 5)
        for i in range(3):
            coin(t, (2.3, -0.8, 0.07 + i * 0.14), 0.5, 0.12)
        coin(t, (-2.05, -0.5, 0.5), 0.5, 0.12, rot=(80, 0, 20))
    else:
        pile(t, [(1.12, 1.0, 10, 30), (1.42, 0.72, 7, 24), (1.7, 0.4, 4, 14), (1.95, 0.0, 1, 0)], 7)
        for (x, y, n) in ((2.4, -0.7, 4), (-2.4, -0.6, 3)):
            for i in range(n):
                coin(t, (x, y, 0.07 + i * 0.14), 0.52, 0.12)
        coin(t, (1.3, -2.0, 0.07), 0.5, 0.12)
        coin(t, (-1.3, -2.1, 0.07), 0.5, 0.12)
        shape(t, "Star", GOLD_L, star5(0.8), 0.25, (0, -0.2, 3.1), bevel=0.06, **METAL)
        shape(t, "Sparkle", GOLD_L, sparkle(0.3), 0.1, (-1.5, -0.3, 2.9), bevel=0.02)
        shape(t, "Sparkle", GOLD_L, sparkle(0.3), 0.1, (1.6, -0.3, 3.1), bevel=0.02)
    return t


def ic_growth_lamp():
    t = Toy("i", rough=0.3)
    t.cyl("Gold", GOLD_D, (0, 0, 0.06), 0.85, 0.12, seg=32, **METAL)
    t.cyl("Gold", GOLD, (0, 0, 0.42), 0.55, 0.6, seg=28, r2=0.3, **METAL)
    E(t, "Gold", GOLD, (0, 0, 1.25), (1.55, 1.05, 0.8), u=28, v=16, **METAL)
    t.cyl("Gold", GOLD, (0, 0, 1.95), 0.4, 0.3, seg=24, r2=0.3, **METAL)
    dome(t, "Gold", GOLD, (0, 0, 2.08), 0.5, 0.36, seg=24, steps=5, **METAL)
    t.sphere("GoldTrim", GOLD_L, (0, 0, 2.5), 0.12, u=12, v=8, **METAL)
    spout = [(-1.2, 0, 1.15), (-1.75, 0, 1.4), (-2.15, 0, 1.85), (-2.2, 0, 2.2)]
    tube(t, "Gold", GOLD, spout, 0.2, seg=14, **METAL)
    t.cyl("GoldTrim", GOLD_L, (-2.2, 0, 2.2), 0.3, 0.18, seg=18, r2=0.22, **METAL)
    E(t, "Glow", "FFB347", (-2.2, 0, 2.62), (0.2, 0.2, 0.46), u=14, v=9, emit=2.0)
    E(t, "Glow", "FFE9A8", (-2.2, 0, 2.55), (0.1, 0.1, 0.26), u=12, v=8, emit=3.0)
    handle = []
    for k in range(9):
        a = math.radians(-70 + k * 22)
        handle.append((1.4 + 0.5 * math.cos(a), 0, 1.3 + 0.7 * math.sin(a)))
    tube(t, "Gold", GOLD, handle, 0.1, seg=10, **METAL)
    for dx in (-0.45, 0.0, 0.45):
        t.sphere("Gem", SKY if dx == 0 else RED, (dx, -1.0, 1.25), 0.16, u=12, v=8, rough=0.15)
    E(t, "Leaf", GREEN, (-0.3, 0, 2.75), (0.4, 0.07, 0.2), rot=(0, 25, 0))
    E(t, "Leaf", LIME, (0.35, 0, 2.85), (0.4, 0.07, 0.2), rot=(0, -25, 0))
    tube(t, "Stem", GREEN_D, [(0, 0, 2.5), (0, 0, 2.75)], 0.06, seg=8)
    shape(t, "Sparkle", GOLD_L, sparkle(0.35), 0.1, (-1.2, -0.4, 3.4), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (-3.1, -0.4, 3.0), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (1.6, -0.4, 3.0), bevel=0.02)
    return t


def ic_festival_boost():
    t = Toy("i", rough=0.4)
    cols = ["FF6FAE", "FFD84D", "4DABF7", "7BE06A"]
    ang = 28
    R = Matrix.Rotation(math.radians(ang), 3, 'Y')
    base = Vector((-1.9, 0, 0.2))
    for i in range(4):
        z0 = i * 0.55
        r0, r1 = 0.28 + i * 0.2, 0.28 + (i + 1) * 0.2
        c = base + R @ Vector((0, 0, z0 + 0.275))
        t.cyl("Popper", cols[i], (c.x, c.y, c.z), r0, 0.55, seg=22, r2=r1, rot=(0, ang, 0))
    top = base + R @ Vector((0, 0, 2.2))
    t.torus("PopperRim", GOLD, (top.x, top.y, top.z), 1.08, 0.09, seg=26, rseg=6, rot=(0, ang, 0), **METAL)
    rnd = random.Random(8)
    ccols = ["FF6FAE", "FFD84D", "4DABF7", "7BE06A", "B197FC", "FF9A3C"]
    for i in range(18):
        d = R @ Vector((rnd.uniform(-0.55, 0.55), rnd.uniform(-0.25, 0.25), 1.0)).normalized()
        dist = rnd.uniform(0.7, 2.6)
        p = top + d * dist
        if i % 3 == 0:
            t.sphere("Confetti", ccols[i % 6], (p.x, p.y, p.z), 0.11, u=8, v=5)
        else:
            t.box("Confetti", ccols[i % 6], (p.x, p.y, p.z), (0.26, 0.05, 0.14), rot=(rnd.uniform(0, 90), rnd.uniform(0, 90), rnd.uniform(0, 90)), bevel=0.0)
    for k in range(2):
        pts = []
        for j in range(8):
            u = j / 7
            d = R @ Vector((0, 0, 1)) * (0.5 + 2.0 * u)
            p = top + d + Vector((math.sin(u * 9 + k * 2) * 0.28 * (k * 2 - 1), 0, 0))
            pts.append((p.x, p.y, p.z))
        tube(t, "Streamer", ccols[k * 2 + 1], pts, 0.045, seg=6)
    bolt = [(0.2, 1.8), (-0.8, -0.1), (-0.05, -0.1), (-0.45, -1.9), (0.85, 0.45), (0.1, 0.45), (0.6, 1.8)]
    shape(t, "BoltEdge", ORANGE, scaled(bolt, 1.0), 0.4, (2.2, 0.2, 1.9), bevel=0.1)
    shape(t, "Bolt", "FFE23D", scaled(bolt, 0.84), 0.5, (2.2, -0.05, 1.9), bevel=0.1, emit=0.4)
    return t


def ic_special_order():
    t = Toy("i", rough=0.4)
    t.box("Gift", "E8453C", (0, 0, 0.8), (2.4, 2.4, 1.6), bevel=0.14)
    t.box("GiftLid", "C23A32", (0, 0, 1.78), (2.6, 2.6, 0.5), bevel=0.12)
    t.box("Ribbon", GOLD_L, (0, -1.22, 0.8), (0.46, 0.06, 1.6), bevel=0.02, **METAL)
    t.box("Ribbon", GOLD_L, (1.22, 0, 0.8), (0.06, 0.46, 1.6), bevel=0.02, **METAL)
    t.box("Ribbon", GOLD_L, (0, 0, 1.8), (0.46, 2.62, 0.56), bevel=0.04, **METAL)
    t.box("Ribbon", GOLD_L, (0, 0, 1.8), (2.62, 0.46, 0.56), bevel=0.04, **METAL)
    for sx in (-1, 1):
        t.torus("Bow", GOLD, (sx * 0.5, 0, 2.3), 0.4, 0.13, seg=20, rseg=7, rot=(90, 0, 0), **METAL)
    t.sphere("Bow", GOLD, (0, 0, 2.15), 0.2, u=14, v=9, **METAL)
    shape(t, "Star", "FFE23D", star5(0.9), 0.3, (0, -0.1, 3.7), bevel=0.07, emit=0.3)
    shape(t, "Sparkle", GOLD_L, sparkle(0.32), 0.1, (-1.7, -0.5, 3.4), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (1.8, -0.5, 3.9), bevel=0.02)
    return t


def ic_complete_now():
    t = Toy("i", rough=0.35)
    for z in (0.1, 3.1):
        t.cyl("Wood", WOOD, (0, 0, z), 1.35, 0.22, seg=32, bevel=0.05)
        t.torus("Trim", GOLD, (0, 0, z + (0.11 if z < 1 else -0.11)), 1.2, 0.05, seg=32, rseg=5, **METAL)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        t.cyl("Post", WOOD_L, (1.1 * math.cos(a), 1.1 * math.sin(a), 1.6), 0.09, 3.0, seg=12)
    prof = [(0, 0.25), (0.75, 0.25), (1.0, 0.55), (1.05, 0.95), (0.85, 1.35), (0.4, 1.5), (0.14, 1.6), (0.4, 1.7), (0.85, 1.85), (1.05, 2.25), (1.0, 2.65), (0.75, 2.95), (0, 2.95)]
    t.lathe("Glass", "CFEFFF", (0, 0, 0), prof, seg=32, rough=0.05)
    t.lathe("Sand", GOLD_L, (0, 0, 0), [(0, 0.27), (0.62, 0.27), (0.8, 0.45), (0.5, 0.78), (0.0, 0.9)], seg=24)
    t.lathe("Sand", GOLD_L, (0, 0, 0), [(0, 1.75), (0.5, 1.95), (0.88, 2.3), (0.9, 2.6), (0.6, 2.75), (0, 2.75)], seg=24)
    t.cyl("Sand", GOLD_L, (0, 0, 1.2), 0.05, 0.8, seg=8)
    tri1 = [(-1.0, 0.85), (0.0, 0), (-1.0, -0.85)]
    tri2 = [(0.05, 0.85), (1.05, 0), (0.05, -0.85)]
    for pts in (tri1, tri2):
        shape(t, "FastEdge", "1E8E4A", scaled(pts, 1.18), 0.5, (2.9, -0.9, 0.95), bevel=0.1)
        shape(t, "Fast", LIME, scaled(pts, 1.0), 0.6, (2.9, -1.0, 0.95), bevel=0.1)
    return t


def ic_legacy_boost():
    t = Toy("i", rough=0.4)
    shape(t, "Star", "FFE23D", star5(1.5), 0.45, (2.0, 0, 2.6), bevel=0.1, emit=0.3)
    shape(t, "StarEdge", GOLD_D, star5(1.72), 0.3, (2.0, 0.15, 2.6), bevel=0.08)
    pts = []
    for j in range(14):
        u = j / 13
        pts.append((2.0 - 4.6 * u, -0.1, 2.6 - 3.6 * (u ** 0.8) + math.sin(u * 6) * 0.35))
    cols = ["FFE23D", "FFB347", "FF8F5A", "FF6FAE", "B197FC", "4DABF7"]
    for k, p in enumerate(pts):
        if k % 2 == 1:
            s = 0.9 - 0.05 * k
            shape(t, "Trail", cols[(k // 2) % 6], star5(max(s, 0.25)), 0.28, (p[0], 0.1, p[2]), bevel=0.06)
    for (x, z, s) in ((-0.6, 2.8, 0.3), (0.2, 3.6, 0.24), (4.4, 0.6, 0.3), (3.6, -0.2, 0.2)):
        shape(t, "Sparkle", GOLD_L, sparkle(s), 0.1, (x, -0.2, z), bevel=0.02)
    return t


def ic_special_pet():
    t = Toy("i", rough=0.4)
    t.torus("Nest", "B8864B", (0, 0, 0.35), 1.25, 0.38, seg=32, rseg=8)
    rnd = random.Random(6)
    for i in range(22):
        a = rnd.uniform(0, 2 * math.pi)
        r0 = rnd.uniform(1.0, 1.55)
        p = (r0 * math.cos(a), r0 * math.sin(a), 0.5 + rnd.uniform(-0.05, 0.15))
        q = (p[0] + rnd.uniform(-0.4, 0.4), p[1] + rnd.uniform(-0.4, 0.4), p[2] + rnd.uniform(0.0, 0.2))
        tube(t, "Straw", "D9B070", [p, q], 0.04, seg=5, joints=False)
    E(t, "Egg", "FFF4D6", (0, 0, 1.75), (1.1, 1.1, 1.45), u=32, v=20)
    t.torus("EggBand", "5CC9C0", (0, 0, 1.35), 1.07, 0.09, seg=32, rseg=6)
    t.torus("EggBand", "FF9AC8", (0, 0, 2.9), 0.5, 0.07, seg=24, rseg=6)
    for (x, z, c) in ((-0.8, 2.3, "FF9AC8"), (0.75, 2.5, "4DABF7"), (-0.55, 1.0, "FFD84D"), (0.9, 1.05, "FF9AC8"), (-0.95, 1.75, "5CC9C0"), (0.3, 3.0, "FFD84D")):
        d = Vector((x, -math.sqrt(max(1.0 - (x / 1.1) ** 2 - ((z - 1.75) / 1.45) ** 2, 0.02)) * 1.1, z - 1.75))
        E(t, "Dot", c, (x, d.y + 0.03, z), (0.13, 0.06, 0.13), u=10, v=6)
    shape(t, "Heart", "F0457A", heart(0.034), 0.45, (0, -0.95, 1.85), bevel=0.1)
    shape(t, "Heart", "FF7FA8", scaled(heart(0.034), 0.7), 0.1, (0.0, -1.2, 1.8), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.32), 0.1, (-1.9, -0.6, 3.1), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (1.9, -0.6, 3.4), bevel=0.02)
    return t


def ic_cosmetic():
    t = Toy("i", rough=0.4)
    hanger(t, PURPLE, r=0.17)
    cz = -1.0
    for sx in (-1, 1):
        pts = [(sx * 0.1, cz + 0.12), (sx * 1.0, cz + 0.5), (sx * 1.0, cz - 0.5), (sx * 0.1, cz - 0.12)]
        shape(t, "Bow", "3F78E8", pts[::sx], 0.26, (0, 0, 0.0), bevel=0.07)
        for dx, dz in ((0.5, 0.18), (0.78, -0.08), (0.4, -0.22), (0.78, 0.3)):
            t.sphere("Dot", WHITE, (sx * dx, -0.17, cz + dz), 0.07, u=8, v=5)
    t.box("Knot", "2A56B8", (0, 0, cz), (0.42, 0.3, 0.56), bevel=0.12)
    shape(t, "Sparkle", "FFE23D", sparkle(1.3, 0.2), 0.3, (2.0, -0.2, 1.5), bevel=0.06, emit=0.3)
    shape(t, "Sparkle", WHITE, sparkle(0.55, 0.2), 0.2, (-1.9, -0.3, 1.9), bevel=0.04, emit=0.2)
    shape(t, "Sparkle", GOLD_L, sparkle(0.4, 0.2), 0.2, (3.3, -0.3, 0.5), bevel=0.04)
    shape(t, "Sparkle", WHITE, sparkle(0.35, 0.2), 0.2, (-3.0, -0.3, 0.3), bevel=0.04)
    return t


def ic_starter_pack():
    t = Toy("i", rough=0.5)
    t.box("Pack", BLUE, (0, 0.2, 1.3), (2.5, 1.7, 2.6), bevel=0.5)
    t.box("Inside", "1C2A5C", (0, 0.2, 2.55), (1.9, 1.2, 0.2), bevel=0.05)
    t.box("PackTop", "F28A2E", (0, 0.2, 2.55), (2.6, 1.8, 0.35), bevel=0.15)
    t.box("Pocket", "F28A2E", (0, -0.78, 0.85), (1.9, 0.55, 1.35), bevel=0.2)
    t.box("Zip", "FFF1D0", (0, -1.07, 1.35), (1.7, 0.05, 0.08), bevel=0.0)
    star6(t, "Star", GOLD, (0, -1.1, 0.75), 0.4, 0.08)
    for sx in (-1, 1):
        t.box("Strap", "1E3E96", (sx * 1.3, 0.2, 1.1), (0.18, 1.2, 1.8), bevel=0.06)
        t.box("Buckle", GOLD, (sx * 0.9, -0.96, 1.95), (0.32, 0.12, 0.2), bevel=0.04, **METAL)
    coin(t, (-0.55, 0.0, 3.35), 0.8, 0.22, rot=(90, 0, 0), emblem=True)
    t.box("Gift", "E8453C", (-1.0, 0.1, 2.9), (0.95, 0.95, 0.8), bevel=0.1, rot=(0, 0, 14))
    t.box("GiftRibbon", GOLD_L, (-1.0, -0.38, 2.9), (0.2, 0.06, 0.82), bevel=0.01, rot=(0, 0, 14))
    shape(t, "Star", "FFE23D", star5(0.7), 0.25, (1.05, -0.1, 3.5), bevel=0.06, emit=0.3)
    shape(t, "Heart", "FF5C8A", heart(0.022), 0.25, (0.6, -0.15, 2.85), bevel=0.05)
    shape(t, "Sparkle", GOLD_L, sparkle(0.3), 0.1, (2.0, -0.4, 4.0), bevel=0.02)
    shape(t, "Sparkle", GOLD_L, sparkle(0.25), 0.1, (-1.9, -0.4, 4.1), bevel=0.02)
    return t


ICONS_SPEC = {
    "pass_double_income": ic_double_income,
    "pass_patron": ic_patron,
    "pass_rapid_growth": ic_rapid_growth,
    "pass_helping_hands": ic_helping_hands,
    "pass_swift_delivery": ic_swift_delivery,
    "pass_quick_merge": ic_quick_merge,
    "pass_golden_wardrobe": ic_golden_wardrobe,
    "pass_pet_lover": ic_pet_lover,
    "product_basket_s": lambda: ic_basket("s"),
    "product_basket_m": lambda: ic_basket("m"),
    "product_basket_l": lambda: ic_basket("l"),
    "product_growth_lamp": ic_growth_lamp,
    "product_festival_boost": ic_festival_boost,
    "product_special_order": ic_special_order,
    "product_complete_now": ic_complete_now,
    "product_legacy_boost": ic_legacy_boost,
    "product_special_pet": ic_special_pet,
    "product_cosmetic": ic_cosmetic,
    "product_starter_pack": ic_starter_pack,
}

DIRS = {
    "pass_helping_hands": (0.3, -1.0, 0.5),
    "pass_double_income": (0.3, -1.0, 0.6),
    "product_basket_s": (0.2, -1.0, 0.55),
    "product_basket_m": (0.2, -1.0, 0.55),
    "product_basket_l": (0.2, -1.0, 0.55),
    "product_complete_now": (0.2, -1.0, 0.2),
}


def make_glass(objs, alpha=0.38):
    for o in objs:
        if o.name.startswith("Glass"):
            m = o.data.materials[0]
            p = m.node_tree.nodes.get("Principled BSDF")
            if p:
                p.inputs["Alpha"].default_value = alpha
            try:
                m.surface_render_method = 'BLENDED'
            except Exception:
                m.blend_method = 'BLEND'


def build_pass_icons(names=None, compose=True):
    os.makedirs(RAW, exist_ok=True)
    out = {}
    for name in (names or list(ICONS_SPEC)):
        reset()
        toy = ICONS_SPEC[name]()
        objs = toy.finish()
        make_glass(objs)
        render_icon(objs, "passes/raw/" + name, size=768, direction=DIRS.get(name, (0.3, -1.0, 0.45)), pad=1.06)
        out[name] = {"tris": tris(objs)}
    if compose:
        r = subprocess.run(["/usr/bin/python3", K + "compose_pass_icons.py"] + (names or []), capture_output=True, text=True)
        out["compose"] = (r.stdout + r.stderr)[-600:]
    return out
