K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())

WOOD, WOOD_D, WOOD_L = "B97A45", "7A4A28", "DDA466"
GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
SILVER = "D5DAE6"
CLOTH, CLOTH_D = "FFFFFF", "E3E7F2"
BLUE = "3B72E0"
PARCH = "F7EBC8"
RED = "C23A4B"
CREAM = "FFF1D0"
FLAME = "FFB347"
INK = "2A2A40"


def table(t, w=3.8, d=2.4, top=2.5, accent=BLUE):
    t.box("Wood", WOOD_D, (0, 0, 0.9), (w - 0.5, d - 0.4, 1.8), bevel=0.15)
    t.box("Cloth", CLOTH, (0, 0, top - 0.06), (w + 0.1, d + 0.1, 0.16), bevel=0.06)
    t.box("Cloth", CLOTH, (0, -d / 2 - 0.02, top - 0.7), (w + 0.1, 0.14, 1.4), bevel=0.05)
    t.box("Cloth", CLOTH, (-w / 2 - 0.02, 0, top - 0.7), (0.14, d + 0.1, 1.4), bevel=0.05)
    t.box("Cloth", CLOTH, (w / 2 + 0.02, 0, top - 0.7), (0.14, d + 0.1, 1.4), bevel=0.05)
    t.box("Accent", accent, (0, -d / 2 - 0.09, top - 1.25), (w + 0.12, 0.08, 0.22), bevel=0.03)
    t.box("Accent", accent, (-w / 2 - 0.09, 0, top - 1.25), (0.08, d + 0.12, 0.22), bevel=0.03)
    t.box("Accent", accent, (w / 2 + 0.09, 0, top - 1.25), (0.08, d + 0.12, 0.22), bevel=0.03)
    t.box("Accent", accent, (0, -d / 2 - 0.09, top - 0.12), (w + 0.12, 0.08, 0.1), bevel=0.03)


def riser(t, w=3.8, base_y=1.05, accent=BLUE):
    t.box("Wood", WOOD_D, (0, base_y, 3.6), (w - 0.2, 0.4, 2.6), bevel=0.14)
    t.box("Accent", accent, (0, base_y - 0.22, 3.6), (w - 0.5, 0.1, 2.2), bevel=0.08)
    t.box("Trim", GOLD, (0, base_y - 0.26, 4.7), (w - 0.4, 0.1, 0.16), bevel=0.04, metal=0.4, rough=0.35)
    for i in range(5):
        x = (i - 2) * 0.62
        t.cyl("Socket", INK, (x, base_y - 0.3, 3.55), 0.26, 0.08, seg=14, rot=(90, 0, 0))
        t.marker("Pip" + str(i + 1), (x, base_y - 0.38, 3.55), (0.3, 0.1, 0.3))


def markers(t, w=3.8, d=2.4, top=2.5):
    t.marker("Top", (0, 0, top + 0.06), (w - 0.2, d - 0.2, 0.12))
    t.marker("CrownSpot", (0, 0.2, 6.2), (0.3, 0.3, 0.3))


def vase(t, x, y, z, flowers=3):
    t.lathe("Vase", "7FB6FF", (x, y, z), [(0, 0), (0.36, 0), (0.46, 0.4), (0.34, 0.8), (0.28, 0.9), (0.34, 1.0), (0, 1.0)], seg=14, rough=0.2)
    cols = ("FF6B8E", "FFD04A", "FFFFFF")
    for i in range(flowers):
        a = i * 2.1
        tube(t, "Stem", "3FA64A", [(x, y, z + 0.9), (x + math.cos(a) * 0.35, y + math.sin(a) * 0.35, z + 1.7 + 0.1 * i)], 0.04, seg=5, joints=False)
        t.sphere("Petal", cols[i % 3], (x + math.cos(a) * 0.35, y + math.sin(a) * 0.35, z + 1.8 + 0.1 * i), 0.24, u=7, v=5)


def station_welcome():
    t = Toy("station_welcome", rough=0.5)
    table(t, accent=BLUE)
    riser(t, accent=BLUE)
    z = 2.6
    t.lathe("Trim", GOLD, (-1.2, -0.2, z), [(0, 0), (0.5, 0), (0.46, 0.18), (0.4, 0.5), (0.22, 0.75), (0.08, 0.82), (0, 0.84)], seg=16, metal=0.6, rough=0.28)
    t.sphere("Trim", GOLD_L, (-1.2, -0.2, z + 0.92), 0.12, u=8, v=5, metal=0.5)
    t.box("Wood", WOOD, (0.15, -0.1, z + 0.08), (1.9, 1.3, 0.14), bevel=0.05)
    t.box("Pages", PARCH, (-0.2, -0.1, z + 0.2), (0.9, 1.1, 0.1), bevel=0.03, rot=(0, -4, 0))
    t.box("Pages", PARCH, (0.5, -0.1, z + 0.2), (0.9, 1.1, 0.1), bevel=0.03, rot=(0, 4, 0))
    t.box("Accent", BLUE, (0.15, -0.1, z + 0.12), (2.0, 1.2, 0.08), bevel=0.04)
    tube(t, "Ink", INK, [(0.9, -0.5, z + 0.3), (1.15, -0.1, z + 0.28)], 0.04, seg=5, joints=False)
    t.sphere("Trim", GOLD, (1.18, -0.08, z + 0.28), 0.06, u=6, v=4)
    vase(t, 1.35, 0.55, z)
    t.box("Cloth", CLOTH_D, (-0.35, 0.65, z + 0.5), (0.9, 0.08, 0.7), bevel=0.04, rot=(-18, 0, 0))
    t.box("Accent", BLUE, (-0.35, 0.58, z + 0.78), (0.7, 0.04, 0.2), bevel=0.02, rot=(-18, 0, 0))
    markers(t)
    return t


def challah(t, x, y, z, rot=0):
    parts = []
    for i in range(7):
        u = (i - 3) / 3.0
        px = u * 0.62
        t.sphere("Challah", "D9954A", (x + math.cos(rot) * px, y + math.sin(rot) * px, z + 0.22 + 0.05 * (1 - u * u)), 0.3, u=8, v=5, scale=(1.0, 1.1, 0.85))
    for i in range(6):
        u = (i - 2.5) / 3.0
        px = u * 0.62
        t.sphere("ChallahDark", "B97732", (x + math.cos(rot) * px, y + math.sin(rot) * px + 0.05, z + 0.34), 0.2, u=7, v=4, scale=(1.0, 1.0, 0.7))


def candlestick(t, x, y, z):
    t.lathe("Trim", GOLD, (x, y, z), [(0, 0), (0.34, 0), (0.3, 0.12), (0.12, 0.35), (0.09, 0.9), (0.2, 1.0), (0.16, 1.12), (0, 1.12)], seg=12, metal=0.6, rough=0.3)
    t.cyl("Candle", CREAM, (x, y, z + 1.45), 0.1, 0.7, seg=8)
    t.sphere("Glow", FLAME, (x, y, z + 1.95), 0.12, u=7, v=5, scale=(0.9, 0.9, 1.6), emit=1.0)


def station_kiddush():
    t = Toy("station_kiddush", rough=0.5)
    table(t, accent="3FA64A")
    riser(t, accent="3FA64A")
    z = 2.6
    for x in (-1.3, -0.6):
        t.lathe("Silver", SILVER, (x, -0.5, z), [(0, 0), (0.3, 0), (0.32, 0.05), (0.14, 0.18), (0.1, 0.3), (0.1, 0.45), (0.3, 0.7), (0.34, 1.0), (0.3, 1.0), (0.26, 0.9), (0, 0.65)], seg=14, metal=0.7, rough=0.25)
        t.cyl("Wine", "A8324A", (x, -0.5, z + 0.88), 0.27, 0.05, seg=12)
    t.lathe("Silver", SILVER, (-0.95, 0.35, z), [(0, 0), (0.6, 0), (0.7, 0.1), (0.5, 0.28), (0.12, 0.4), (0.08, 0.7), (0.2, 0.95), (0.55, 1.5), (0.4, 1.5), (0.16, 1.1), (0, 0.8)], seg=16, metal=0.7, rough=0.28)
    challah(t, 0.55, -0.35, z, 0.1)
    challah(t, 0.7, 0.35, z, -0.1)
    t.box("Cloth", CLOTH_D, (1.35, -0.55, z + 0.4), (0.9, 0.9, 0.8), bevel=0.2)
    t.box("Accent", "3FA64A", (1.35, -0.55, z + 0.82), (0.7, 0.7, 0.06), bevel=0.02)
    candlestick(t, -1.5, 0.7, z)
    candlestick(t, -0.4, 0.8, z)
    markers(t)
    return t


def station_desk():
    t = Toy("station_desk", rough=0.5)
    t.box("Wood", WOOD, (0, 0, 2.3), (3.8, 2.4, 0.3), bevel=0.12)
    t.box("WoodDark", WOOD_D, (-1.5, 0, 1.1), (0.7, 2.0, 2.2), bevel=0.14)
    t.box("WoodDark", WOOD_D, (1.5, 0, 1.1), (0.7, 2.0, 2.2), bevel=0.14)
    t.box("WoodDark", WOOD_D, (0, 0.85, 1.4), (2.6, 0.3, 1.6), bevel=0.1)
    for sx in (-1.5, 1.5):
        for z in (0.5, 1.4, 1.9):
            t.box("Wood", WOOD_L, (sx, -1.05, z), (0.55, 0.06, 0.6 if z < 1.8 else 0.3), bevel=0.04)
            t.sphere("Trim", GOLD, (sx, -1.12, z), 0.09, u=6, v=4, metal=0.5)
    t.box("Accent", "7A4FD0", (0, -1.0, 2.0), (2.5, 0.08, 0.16), bevel=0.03)
    riser(t, accent="7A4FD0")
    z = 2.5
    t.box("Ledger", "2E7A4A", (-0.7, -0.1, z + 0.14), (1.5, 1.1, 0.26), bevel=0.06)
    t.box("Pages", PARCH, (-0.62, -0.1, z + 0.17), (1.35, 0.98, 0.26), bevel=0.02)
    t.box("Ledger", "2E7A4A", (-0.7, -0.1, z + 0.31), (1.5, 1.1, 0.06), bevel=0.04, rot=(0, -3, 0))
    tube(t, "Ink", INK, [(0.1, -0.5, z + 0.2), (0.45, -0.1, z + 0.6)], 0.045, seg=5, joints=False)
    t.sphere("Trim", GOLD, (0.47, -0.08, z + 0.64), 0.07, u=6, v=4)
    t.cyl("Wood", WOOD_D, (1.3, -0.4, z + 0.2), 0.34, 0.4, seg=12)
    t.cyl("Accent", "7A4FD0", (1.3, -0.4, z + 0.45), 0.2, 0.2, seg=12)
    t.box("Blue", BLUE, (1.35, 0.5, z + 0.5), (0.8, 0.8, 1.0), bevel=0.14)
    t.box("Slot", INK, (1.35, 0.1, z + 0.85), (0.4, 0.06, 0.06), bevel=0.01)
    t.box("Trim", GOLD, (1.35, 0.1, z + 0.55), (0.34, 0.04, 0.34), bevel=0.02)
    star6(t, "Trim", GOLD_L, (1.35, 0.08, z + 0.55), 0.22, 0.03)
    markers(t, top=2.5)
    return t


def station_mirror():
    t = Toy("station_mirror", rough=0.45)
    t.box("WoodDark", WOOD_D, (0, 0, 0.45), (4.0, 2.2, 0.9), bevel=0.22)
    t.box("Wood", WOOD, (0, 0.75, 4.5), (3.6, 0.5, 7.4), bevel=0.25)
    t.box("Glass", "BFE9FF", (0, 0.45, 4.2), (2.8, 0.1, 6.0), bevel=0.04, rough=0.05)
    for sx in (-1.55, 1.55):
        t.cyl("Trim", GOLD, (sx, 0.55, 4.4), 0.24, 6.6, seg=10, metal=0.5, rough=0.3)
        t.sphere("Trim", GOLD_L, (sx, 0.55, 7.9), 0.3, u=8, v=5, metal=0.5)
    t.box("Trim", GOLD, (0, 0.5, 7.25), (3.4, 0.4, 0.36), bevel=0.12, metal=0.5, rough=0.3)
    t.box("Trim", GOLD, (0, 0.5, 1.2), (3.4, 0.4, 0.3), bevel=0.1, metal=0.5, rough=0.3)
    t.cyl("Trim", GOLD, (0, 0.5, 8.2), 1.0, 0.6, seg=14, r2=0.7, metal=0.5, rough=0.3)
    t.sphere("Glow", "FFE08A", (0, 0.5, 8.9), 0.6, u=12, v=8, emit=0.8)
    star6(t, "Trim", GOLD_L, (0, 0.2, 7.25), 0.32, 0.06)
    t.marker("Top", (0, 0.4, 4.2), (2.6, 0.2, 5.8))
    return t


BUILDERS = {"welcome": station_welcome, "kiddush": station_kiddush, "desk": station_desk, "mirror": station_mirror}
DIRS = {k: (0.5, -1.0, 0.45) for k in BUILDERS}


def build_interior(names=None, do_export=False):
    return build_set(BUILDERS, names, do_export, "station_", 384, DIRS)
