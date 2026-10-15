K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "kit2.py").read())

CREAM = "FFF1D0"
PARCH = "F4E3B5"
WOOD_L, WOOD, WOOD_D = "C98B52", "9A5E33", "6B3E22"
GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
SILVER = "D5DAE6"
BLUE, BLUE_D = "2E5BD0", "1E3E96"
RED = "C23A4B"
FLAME = "FFB347"
WHITE = "FFFFFF"
SKY = "3FA7FF"

_orig_sphere = Toy.sphere


def _sphere(self, label, hexs, c, r, u=None, v=None, **kw):
    if u is None:
        u, v = (10, 6) if r < 0.2 else ((14, 8) if r < 0.45 else (20, 12))
    _orig_sphere(self, label, hexs, c, r, u=u, v=v, **kw)


Toy.sphere = _sphere


def star6(t, label, hexs, c, r, thick):
    for flip in (1, -1):
        pts = [(0, r * flip), (-r * 0.866, -r * 0.5 * flip), (r * 0.866, -r * 0.5 * flip)]
        pts = [(c[0] + x, c[2] + z) for x, z in pts]
        t.poly(label, hexs, pts, c[1] - thick / 2, c[1] + thick / 2, bevel=min(0.03, thick * 0.3), plane="XZ")


def tube(t, label, hexs, pts, r, seg=10, **kw):
    for a, b in zip(pts, pts[1:]):
        va, vb = Vector(a), Vector(b)
        d = vb - va
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        e = q.to_euler('XYZ')
        mid = (va + vb) / 2
        t.cyl(label, hexs, (mid.x, mid.y, mid.z), r, d.length, seg=seg,
              rot=(math.degrees(e.x), math.degrees(e.y), math.degrees(e.z)), **kw)
    for p in pts[1:-1]:
        t.sphere(label, hexs, p, r, u=8, v=5, **kw)


def item_torah():
    t = Toy("torah", rough=0.4)
    t.cyl("Wood", WOOD_D, (0, 0, 0.07), 0.88, 0.14, seg=32, bevel=0.03)
    t.torus("Trim", GOLD, (0, 0, 0.16), 0.8, 0.05, seg=32)
    t.cyl("Wood", WOOD, (-0.42, 0, 1.8), 0.09, 3.1, seg=14)
    t.cyl("Wood", WOOD, (0.42, 0, 1.8), 0.09, 3.1, seg=14)
    t.cyl("Trim", GOLD, (-0.42, 0, 3.4), 0.2, 0.18, seg=14, r2=0.13)
    t.cyl("Trim", GOLD, (0.42, 0, 3.4), 0.2, 0.18, seg=14, r2=0.13)
    t.sphere("Trim", GOLD_L, (-0.42, 0, 3.58), 0.17)
    t.sphere("Trim", GOLD_L, (0.42, 0, 3.58), 0.17)
    t.lathe("Accent", BLUE, (0, 0, 0), [(0, 0.14), (0.74, 0.14), (0.78, 0.4), (0.74, 1.8), (0.68, 2.55),
                                          (0.5, 2.98), (0.2, 3.1), (0, 3.1)], seg=28, scale=(1, 0.78, 1), rough=0.75)
    t.lathe("Trim", GOLD, (0, 0, 0), [(0.8, 0.46), (0.8, 0.6)], seg=28, scale=(1, 0.78, 1), metal=0.4, rough=0.35)
    t.lathe("Trim", GOLD, (0, 0, 0), [(0.72, 2.3), (0.72, 2.44)], seg=28, scale=(1, 0.78, 1), metal=0.4, rough=0.35)
    t.box("Silver", SILVER, (0, -0.58, 1.95), (0.78, 0.12, 0.95), bevel=0.06, metal=0.7, rough=0.28)
    t.sphere("Gem", RED, (0, -0.67, 2.15), 0.11)
    t.sphere("Gem", SKY, (-0.2, -0.67, 1.75), 0.08)
    t.sphere("Gem", SKY, (0.2, -0.67, 1.75), 0.08)
    t.torus("Trim", GOLD, (0, 0, 3.12), 0.3, 0.05, seg=24)
    for i in range(6):
        a = 2 * math.pi * i / 6
        t.cyl("Trim", GOLD, (math.cos(a) * 0.3, math.sin(a) * 0.3, 3.36), 0.07, 0.46, seg=10, r2=0.0)
        t.sphere("Gem", RED if i % 2 == 0 else SKY, (math.cos(a) * 0.3, math.sin(a) * 0.3, 3.62), 0.05)
    t.sphere("Trim", GOLD_L, (0, 0, 3.4), 0.1)
    return t


def item_ark():
    t = Toy("ark", rough=0.45)
    t.box("Wood", WOOD_D, (0, 0, 0.3), (6.6, 2.7, 0.6), bevel=0.1)
    t.box("Wood", WOOD, (0, 0, 3.7), (5.7, 2.1, 6.2), bevel=0.14)
    for x in (-1.37, 1.37):
        t.box("Trim", GOLD, (x, -1.1, 3.5), (2.7, 0.08, 5.4), bevel=0.05, metal=0.4, rough=0.3)
        t.box("Accent", RED, (x, -1.16, 3.5), (2.4, 0.1, 5.1), bevel=0.1, rough=0.5)
        t.box("Trim", GOLD_D, (x, -1.22, 3.5), (1.9, 0.06, 4.6), bevel=0.05, metal=0.4, rough=0.3)
        t.box("Accent", "A82D3E", (x, -1.25, 3.5), (1.7, 0.05, 4.4), bevel=0.05, rough=0.5)
        star6(t, "Trim", GOLD_L, (x, -1.31, 3.7), 0.55, 0.06)
    t.box("Trim", GOLD_D, (0, -1.2, 3.5), (0.1, 0.1, 5.4), bevel=0.02)
    for x in (-0.28, 0.28):
        t.torus("Trim", GOLD_L, (x, -1.32, 3.1), 0.17, 0.045, seg=18, rot=(90, 0, 0))
    for x in (-3.1, 3.1):
        t.cyl("Trim", CREAM, (x, -0.9, 3.7), 0.34, 6.2, seg=24)
        t.cyl("Trim", GOLD, (x, -0.9, 6.9), 0.44, 0.34, seg=24)
        t.cyl("Trim", GOLD, (x, -0.9, 0.78), 0.44, 0.34, seg=24)
    t.box("Wood", WOOD, (0, 0, 7.05), (6.4, 2.3, 0.5), bevel=0.1)
    t.poly("Wood", WOOD_L, [(-3.2, 7.3), (3.2, 7.3), (0, 8.7)], -1.1, 1.1, bevel=0.08, plane="XZ")
    t.poly("Trim", GOLD, [(-2.6, 7.4), (2.6, 7.4), (0, 8.4)], -1.2, -1.1, bevel=0.03, plane="XZ")
    for x in (-0.4, 0.4):
        t.box("Trim", GOLD_L, (x, -1.25, 7.85), (0.58, 0.1, 0.6), bevel=0.1)
        t.cyl("Trim", GOLD_L, (x, -1.25, 8.15), 0.29, 0.1, seg=18, rot=(90, 0, 0))
    t.torus("Trim", GOLD, (0, -1.0, 9.0), 0.4, 0.07, seg=20, rot=(90, 0, 0))
    t.sphere("Gem", SKY, (0, -1.0, 9.0), 0.16)
    return t


def item_siddur():
    t = Toy("siddur", rough=0.55)
    t.box("Wood", WOOD, (0, 0.0, 0.07), (1.5, 0.95, 0.14), bevel=0.05)
    t.box("Wood", WOOD_D, (0, -0.42, 0.28), (1.5, 0.1, 0.3), bevel=0.04)
    rot = (-14, 0, 0)
    t.box("Pages", PARCH, (0.04, 0.0, 0.92), (0.92, 0.28, 1.28), rot=rot, bevel=0.02)
    t.box("Accent", BLUE, (0, 0.0, 0.92), (0.98, 0.34, 1.34), rot=rot, bevel=0.06, rough=0.6)
    t.box("Pages", PARCH, (0.06, 0.0, 0.92), (0.86, 0.36, 1.2), rot=rot, bevel=0.01)
    t.box("Accent", BLUE_D, (-0.47, -0.01, 0.92), (0.1, 0.38, 1.36), rot=rot, bevel=0.04, rough=0.6)
    star6(t, "Trim", GOLD, (0.0, -0.2, 1.07), 0.22, 0.04)
    t.box("Trim", GOLD, (0.0, -0.2, 0.62), (0.5, 0.04, 0.05), bevel=0.01)
    t.box("Ribbon", RED, (0.18, -0.04, 1.62), (0.07, 0.04, 0.5), bevel=0.01)
    return t


def item_menorah():
    t = Toy("menorah", rough=0.3)
    gold = dict(metal=0.75, rough=0.26)
    t.cyl("Gold", GOLD_D, (0, 0, 0.12), 1.0, 0.24, seg=32, r2=0.82, **gold)
    t.cyl("Gold", GOLD, (0, 0, 0.5), 0.52, 0.52, seg=24, r2=0.3, **gold)
    t.sphere("Gold", GOLD_L, (0, 0, 0.84), 0.3, **gold)
    for i in range(3):
        a = 2 * math.pi * i / 3 + math.pi / 2
        t.sphere("Accent", RED, (math.cos(a) * 0.78, math.sin(a) * 0.78, 0.26), 0.11)
    top = 3.1
    t.cyl("Gold", GOLD, (0, 0, (0.84 + top) / 2), 0.11, top - 0.84, seg=14, **gold)
    for z in (1.4, 2.2):
        t.sphere("Gold", GOLD_L, (0, 0, z), 0.2, **gold)
    for side in (-1, 1):
        for x in (0.55, 1.1, 1.65):
            h = top - x
            pts = []
            n = 8
            for i in range(n + 1):
                a = math.radians(-90 + 90 * i / n)
                pts.append((side * x * math.cos(a), 0, h + x + x * math.sin(a)))
            tube(t, "Gold", GOLD, pts, 0.08, seg=8, **gold)
            t.sphere("Gold", GOLD_L, (side * x * 0.3827, 0, h + x - x * 0.9239), 0.12, **gold)
            t.cyl("Gold", GOLD_L, (side * x, 0, top - 0.02), 0.2, 0.2, seg=12, r2=0.13, **gold)
            t.sphere("Glow", FLAME, (side * x, 0, top + 0.26), 0.13, scale=(0.9, 0.9, 1.7), emit=1.0)
    t.cyl("Gold", GOLD_L, (0, 0, top - 0.02), 0.2, 0.2, seg=16, r2=0.13, **gold)
    t.sphere("Glow", FLAME, (0, 0, top + 0.26), 0.13, scale=(0.9, 0.9, 1.7), emit=1.0)
    return t


def item_kiddush_cup():
    t = Toy("kiddush_cup", rough=0.25)
    sil = dict(metal=0.8, rough=0.22)
    t.lathe("Silver", SILVER, (0, 0, 0), [(0, 0), (0.55, 0), (0.58, 0.07), (0.28, 0.2), (0.12, 0.34), (0.12, 0.55),
                                           (0.2, 0.62), (0.12, 0.72), (0.12, 0.82), (0.5, 1.1), (0.58, 1.6),
                                           (0.5, 1.72), (0.46, 1.64), (0, 1.12)], seg=32, **sil)
    t.torus("Trim", GOLD, (0, 0, 1.68), 0.54, 0.04, seg=32, metal=0.8, rough=0.2)
    t.cyl("Accent", RED, (0, 0, 1.46), 0.47, 0.05, seg=30, rough=0.3)
    t.torus("Trim", GOLD, (0, 0, 0.62), 0.2, 0.035, seg=20, metal=0.8, rough=0.2)
    star6(t, "Trim", GOLD, (0, -0.55, 1.2), 0.17, 0.03)
    return t


def item_chandelier():
    t = Toy("chandelier", rough=0.3)
    brass = dict(metal=0.8, rough=0.28)
    t.cyl("Gold", GOLD_D, (0, 0, -0.15), 0.5, 0.3, seg=20, r2=0.3, **brass)
    t.cyl("Gold", GOLD, (0, 0, -1.1), 0.09, 1.6, seg=10, **brass)
    for z in (-0.6, -1.1, -1.6):
        t.torus("Gold", GOLD_L, (0, 0, z), 0.15, 0.05, seg=12, rseg=6, **brass)
    t.lathe("Gold", GOLD, (0, 0, -2.9), [(0, 1.1), (0.3, 1.0), (0.55, 0.6), (0.36, 0.3), (0.26, 0.05), (0.34, -0.3),
                                          (0.18, -0.6), (0.2, -1.1), (0, -1.3)], seg=20, **brass)
    for (ring_r, ring_z, count) in ((1.15, -2.55, 6), (2.15, -3.1, 8)):
        t.torus("Gold", GOLD_D, (0, 0, ring_z), ring_r, 0.1, seg=32, rseg=8, **brass)
        for i in range(count):
            a = 2 * math.pi * i / count
            x, y = math.cos(a) * ring_r, math.sin(a) * ring_r
            tube(t, "Gold", GOLD, [(0, 0, -2.85), (x * 0.5, y * 0.5, ring_z - 0.35), (x, y, ring_z)], 0.07, seg=8, **brass)
            t.cyl("Gold", GOLD_L, (x, y, ring_z + 0.14), 0.19, 0.26, seg=10, r2=0.13, **brass)
            t.cyl("Candle", CREAM, (x, y, ring_z + 0.55), 0.11, 0.6, seg=8)
            t.sphere("Glow", FLAME, (x, y, ring_z + 1.0), 0.14, scale=(0.9, 0.9, 1.6), emit=1.0)
            t.sphere("Crystal", "BFE9FF", (x, y, ring_z - 0.42), 0.12, scale=(1, 1, 1.5), rough=0.05, u=8, v=5)
    t.sphere("Accent", BLUE, (0, 0, -4.35), 0.34)
    return t


def item_ornament():
    t = Toy("ornament", rough=0.3)
    t.cyl("Wood", WOOD_D, (0, 0.1, 0), 1.25, 0.2, seg=36, rot=(90, 0, 0), bevel=0.04)
    t.torus("Trim", GOLD, (0, -0.08, 0), 1.08, 0.12, seg=36, rot=(90, 0, 0), metal=0.6, rough=0.28)
    t.cyl("Accent", BLUE, (0, -0.06, 0), 0.98, 0.1, seg=36, rot=(90, 0, 0), rough=0.4)
    t.torus("Trim", GOLD_L, (0, -0.12, 0), 0.72, 0.045, seg=36, rot=(90, 0, 0), metal=0.6, rough=0.28)
    star6(t, "Trim", GOLD, (0, -0.17, 0), 0.5, 0.09)
    t.sphere("Gem", WHITE, (0, -0.24, 0), 0.1)
    for i in range(8):
        a = math.radians(i * 45)
        t.sphere("Trim", GOLD_L, (math.cos(a) * 1.18, -0.1, math.sin(a) * 1.18), 0.09)
    return t


def item_holiday_decor():
    t = Toy("holiday_decor", rough=0.45)
    n = 9
    pts = []
    for i in range(n + 1):
        u = i / n
        pts.append((-1.9 + 3.8 * u, 0.0, -0.5 * math.sin(math.pi * u)))
    tube(t, "Trim", GOLD, pts, 0.035, seg=8)
    colors = (BLUE, WHITE, GOLD, SKY, WHITE, GOLD, BLUE, WHITE)
    for i in range(n - 1):
        x, _, z = pts[i + 1]
        label = "Accent" if i % 2 == 0 else "Flag"
        t.poly(label, colors[i % len(colors)], [(x - 0.22, z), (x + 0.22, z), (x, z - 0.62)], -0.03, 0.03,
               bevel=0.01, plane="XZ")
    for sx in (-1, 1):
        t.sphere("Trim", GOLD, (sx * 1.9, 0, 0.0), 0.12)
    star6(t, "Trim", GOLD, (0, -0.06, -0.62), 0.2, 0.04)
    return t


ITEMS = {
    "torah": item_torah, "ark": item_ark, "siddur": item_siddur, "menorah": item_menorah,
    "kiddush_cup": item_kiddush_cup, "chandelier": item_chandelier, "ornament": item_ornament,
    "holiday_decor": item_holiday_decor,
}

ITEM_DIR = {
    "chandelier": (0.55, -1.0, 0.1), "holiday_decor": (0.3, -1.0, 0.1), "ornament": (0.25, -1.0, 0.2),
    "ark": (0.5, -1.0, 0.35),
}


def build_items(names=None, do_export=False):
    out = {}
    for name in (names or list(ITEMS)):
        reset()
        toy = ITEMS[name]()
        objs = toy.finish()
        render_icon(objs, "item_" + name, size=384, direction=ITEM_DIR.get(name, (0.5, -1.0, 0.45)), pad=1.12)
        entry = {"parts": len(objs), "tris": tris(objs)}
        if do_export:
            entry.update(export(name, objs))
        out[name] = entry
    return out
