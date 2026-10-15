K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())

STONE, STONE_D, STONE_L = "D9DCE8", "A8AEC6", "F0F2FA"
WATER, WATER_D = "63C4FF", "3E98EE"
GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
RED_FLAG = "FF6B6B"
WOOD, WOOD_D, WOOD_L = "B97A45", "7A4A28", "DDA466"
IRON = "3A3F5A"
BLUE, BLUE_D = "3B72E0", "27499E"
LEAF_A, LEAF_B, LEAF_C, LEAF_D = "46C455", "2FA03F", "7BE063", "21822F"
PINK, PINK_D = "FF9DC4", "F26FA0"
CREAM = "FFF1D0"


def prop_fountain():
    t = Toy("prop_fountain", rough=0.5)
    basin = [(0, 0), (14.2, 0), (15.1, 0.3), (15.7, 1.3), (15.7, 2.3), (15.3, 2.8), (14.5, 2.8), (14.1, 2.4), (13.7, 1.1), (0, 1.1)]
    t.lathe("Stone", STONE, (0, 0, 0), basin, seg=44)
    t.lathe("Accent", BLUE, (0, 0, 0), [(15.74, 1.0), (15.74, 1.75)], seg=44)
    t.torus("Trim", GOLD, (0, 0, 2.84), 14.9, 0.2, seg=44, rseg=6, metal=0.4, rough=0.35)
    for i in range(22):
        a = 2 * math.pi * i / 22
        t.sphere("StoneLight", STONE_L, (math.cos(a) * 15.45, math.sin(a) * 15.45, 2.9), 0.52, u=8, v=5)
    t.cyl("Water", WATER, (0, 0, 2.0), 13.9, 0.2, seg=44, rough=0.15)
    t.lathe("Stone", STONE, (0, 0, 0), [(0, 1.0), (4.2, 1.0), (4.2, 1.9), (2.2, 3.2), (1.5, 5.6), (2.7, 6.2), (2.7, 6.6), (0, 6.6)], seg=28)
    bowl(t, "StoneLight", STONE_L, (0, 0, 6.4), 8.4, 7.5, 2.4, 0.55, seg=40)
    t.torus("Trim", GOLD, (0, 0, 8.8), 7.9, 0.2, seg=40, rseg=6, metal=0.4, rough=0.35)
    t.cyl("Water", WATER, (0, 0, 7.9), 7.3, 0.2, seg=40, rough=0.15)
    t.lathe("Stone", STONE, (0, 0, 0), [(0, 6.9), (1.7, 6.9), (1.15, 9.5), (1.8, 10.2), (1.8, 10.7), (0, 10.7)], seg=24)
    bowl(t, "StoneLight", STONE_L, (0, 0, 10.6), 4.4, 3.8, 1.6, 0.45, seg=32)
    t.torus("Trim", GOLD, (0, 0, 12.1), 4.1, 0.15, seg=32, rseg=6, metal=0.4, rough=0.35)
    t.cyl("Water", WATER, (0, 0, 11.6), 3.7, 0.18, seg=32, rough=0.15)
    t.cyl("Stone", STONE, (0, 0, 12.4), 0.65, 1.4, seg=12, r2=0.4)
    t.sphere("Trim", GOLD, (0, 0, 13.4), 1.05, u=16, v=10, metal=0.5, rough=0.3)
    for i in range(6):
        a = 2 * math.pi * i / 6
        t.sphere("Trim", GOLD_L, (math.cos(a) * 1.2, math.sin(a) * 1.2, 13.9), 0.24, u=8, v=5, metal=0.4)
    for i in range(4):
        a = math.pi / 4 + math.pi / 2 * i
        t.sphere("StoneLight", STONE_L, (math.cos(a) * 12.2, math.sin(a) * 12.2, 2.4), 1.0, u=10, v=6, scale=(1, 1, 0.8))
        t.sphere("Trim", GOLD, (math.cos(a) * 12.2, math.sin(a) * 12.2, 3.35), 0.34, u=8, v=5, metal=0.4)
    t.marker("SprayAnchor", (0, 0, 14.6), (0.4, 0.4, 0.4))
    return t


def tree_round(t, trunk_h=4.4, base=0.0, canopy=None):
    t.cyl("Trunk", WOOD_D, (0, 0, trunk_h / 2), 0.95, trunk_h, seg=10, r2=0.6)
    for a in (0.3, 2.4, 4.4):
        t.sphere("Trunk", WOOD_D, (math.cos(a) * 0.9, math.sin(a) * 0.9, 0.35), 0.55, u=8, v=5, scale=(1, 1, 0.6))


def prop_tree():
    t = Toy("prop_tree", rough=0.55)
    tree_round(t)
    for (x, y, z, r, label, hx) in ((0, 0, 7.0, 3.9, "LeavesA", LEAF_A), (-2.2, 0.8, 6.0, 2.8, "LeavesB", LEAF_B), (2.3, -0.5, 6.4, 2.9, "LeavesB", LEAF_B),
                                    (0.4, 1.4, 9.4, 2.7, "LeavesC", LEAF_C), (-1.0, -1.5, 8.7, 2.3, "LeavesC", LEAF_C), (1.6, 0.9, 5.2, 2.2, "LeavesD", LEAF_D)):
        t.sphere(label, hx, (x, y, z), r, u=14, v=9)
    return t


def prop_tree2():
    t = Toy("prop_tree2", rough=0.55)
    tree_round(t, 3.6)
    for (x, y, z, r, hx) in ((0, 0, 6.4, 3.6, PINK), (-2.0, 0.6, 5.5, 2.5, PINK_D), (2.1, -0.4, 5.8, 2.6, PINK_D), (0.3, 1.2, 8.6, 2.5, PINK), (-0.9, -1.3, 7.9, 2.1, "FFC2DA")):
        t.sphere("Blossom", hx, (x, y, z), r, u=14, v=9)
    for i in range(9):
        a = 2 * math.pi * i / 9 + 0.4
        t.sphere("Petal", "FFFFFF", (math.cos(a) * 3.5, math.sin(a) * 3.5, 5.0 + (i % 3) * 1.4), 0.25, u=6, v=4)
    return t


def prop_tree3():
    t = Toy("prop_tree3", rough=0.55)
    t.cyl("Trunk", WOOD_D, (0, 0, 1.2), 0.8, 2.4, seg=10, r2=0.55)
    for i, (r, z, h) in enumerate(((4.4, 2.2, 3.6), (3.6, 4.4, 3.4), (2.8, 6.4, 3.2), (1.9, 8.2, 3.0))):
        t.cyl("LeavesA" if i % 2 == 0 else "LeavesD", LEAF_A if i % 2 == 0 else LEAF_D, (0, 0, z + h / 2), r, h, seg=12, r2=0.15 + 0.1 * (3 - i))
    t.sphere("Star", GOLD, (0, 0, 11.4), 0.4, u=8, v=5, metal=0.4)
    return t


def prop_bush():
    t = Toy("prop_bush", rough=0.55)
    for (x, y, z, r, hx) in ((0, 0, 1.4, 1.9, LEAF_A), (-1.5, 0.3, 1.0, 1.4, LEAF_B), (1.5, -0.2, 1.1, 1.5, LEAF_B), (0.2, 0.9, 2.2, 1.3, LEAF_C)):
        t.sphere("Leaves", hx, (x, y, z), r, u=12, v=8)
    for (x, y, z) in ((-0.8, -1.4, 1.6), (1.0, -1.3, 1.9), (0.1, -1.6, 2.6)):
        t.sphere("Berry", "FF5A7A", (x, y, z), 0.24, u=6, v=4)
    return t


def prop_rock():
    t = Toy("prop_rock", rough=0.8)
    t.sphere("Rock", "A3A9BC", (0, 0, 0.9), 1.7, u=9, v=6, scale=(1.2, 1.0, 0.75))
    t.sphere("RockLight", "C4C9D8", (-1.5, 0.6, 0.55), 0.95, u=8, v=5, scale=(1.1, 1.0, 0.7))
    t.sphere("Rock", "8E94AB", (1.3, 0.8, 0.45), 0.8, u=8, v=5, scale=(1.1, 1.0, 0.7))
    return t


def prop_bench():
    t = Toy("prop_bench", rough=0.55)
    for i, y in enumerate((-0.62, 0.0, 0.62)):
        t.box("Wood", WOOD if i % 2 == 0 else WOOD_L, (0, y, 1.75), (6.2, 0.56, 0.26), bevel=0.09)
    for i, z in enumerate((2.45, 3.0, 3.55)):
        t.box("Wood", WOOD_L if i % 2 == 0 else WOOD, (0, 1.0 - (z - 2.45) * 0.2, z), (6.2, 0.2, 0.46), rot=(-11, 0, 0), bevel=0.07)
    for sx in (-2.75, 2.75):
        tube(t, "Iron", IRON, [(sx, -0.75, 0.0), (sx, -0.7, 1.55)], 0.11, seg=8)
        tube(t, "Iron", IRON, [(sx, 0.95, 0.0), (sx, 1.0, 1.6), (sx, 1.2, 3.8)], 0.11, seg=8)
        tube(t, "Iron", IRON, [(sx, -0.8, 2.55), (sx, -0.2, 2.62), (sx, 0.9, 2.5)], 0.1, seg=8)
        t.sphere("Iron", IRON, (sx, -0.88, 2.55), 0.2, u=8, v=5)
        t.torus("Iron", IRON, (sx, -0.2, 1.1), 0.34, 0.06, seg=14, rseg=5, rot=(0, 90, 0))
    t.box("Iron", IRON, (0, 0, 1.55), (5.6, 0.14, 0.14), bevel=0.04)
    return t


def prop_lamp():
    t = Toy("prop_lamp", rough=0.4)
    t.lathe("Iron", IRON, (0, 0, 0), [(0, 0), (1.4, 0), (1.4, 0.35), (1.0, 0.9), (0.55, 1.6), (0.38, 2.4), (0, 2.4)], seg=14)
    t.cyl("Iron", IRON, (0, 0, 5.6), 0.28, 6.4, seg=8)
    t.torus("Trim", GOLD, (0, 0, 3.0), 0.46, 0.1, seg=14, rseg=5, metal=0.4)
    t.torus("Trim", GOLD, (0, 0, 8.7), 0.5, 0.1, seg=14, rseg=5, metal=0.4)
    t.cyl("Iron", IRON, (0, 0, 9.05), 1.2, 0.5, seg=12, r2=0.8)
    t.sphere("Glow", "FFE9A0", (0, 0, 10.35), 1.05, u=12, v=8, emit=1.0)
    for (sx, sy) in ((0.82, 0.82), (-0.82, 0.82), (0.82, -0.82), (-0.82, -0.82)):
        tube(t, "Iron", IRON, [(sx * 0.9, sy * 0.9, 9.45), (sx, sy, 10.35), (sx * 0.9, sy * 0.9, 11.25)], 0.07, seg=6, joints=False)
    t.cyl("Iron", IRON, (0, 0, 11.7), 1.55, 0.9, seg=12, r2=0.2)
    t.sphere("Trim", GOLD, (0, 0, 12.4), 0.28, u=8, v=5, metal=0.4)
    return t


def prop_fence():
    t = Toy("prop_fence", rough=0.55)
    for sx in (-4.0, 4.0):
        t.box("WoodDark", WOOD_D, (sx, 0, 2.1), (0.9, 0.9, 4.2), bevel=0.16)
        t.sphere("WoodLight", WOOD_L, (sx, 0, 4.3), 0.62, u=10, v=6)
    for z in (1.2, 2.7):
        t.box("WoodDark", WOOD_D, (0, 0.28, z), (8.0, 0.28, 0.45), bevel=0.07)
    for i in range(7):
        x = -3.0 + i * 1.0
        t.box("Wood", WOOD if i % 2 == 0 else WOOD_L, (x, -0.05, 1.7), (0.62, 0.26, 3.2), bevel=0.07)
        t.poly("Wood" if i % 2 == 0 else "WoodLight", WOOD if i % 2 == 0 else WOOD_L, [(x - 0.31, 3.3), (x + 0.31, 3.3), (x, 3.78)], -0.18, 0.08, bevel=0.03, plane="XZ")
    return t


def prop_flowers():
    t = Toy("prop_flowers", rough=0.5)
    t.box("WoodDark", WOOD_D, (0, 0, 0.5), (6.2, 3.0, 1.0), bevel=0.26)
    t.box("Soil", "5E3E2B", (0, 0, 1.0), (5.5, 2.35, 0.2), bevel=0.06)
    colors = ("FF6B8E", "FFD04A", "B58BFF", "FFFFFF", "5BA8FF", "FF9A3C", "FF6B8E")
    for i in range(7):
        x = -2.4 + i * 0.8
        y = 0.45 if i % 2 else -0.45
        h = 1.2 + (i % 3) * 0.35
        tube(t, "Stem", "3FA64A", [(x, y, 1.0), (x + 0.04, y, 1.0 + h)], 0.07, seg=5, joints=False)
        t.sphere("Leaf", "3FA64A", (x + 0.22, y, 1.0 + h * 0.45), 0.2, u=6, v=4, scale=(1.4, 0.4, 0.7))
        col = colors[i]
        top = 1.0 + h + 0.1
        for k in range(5):
            a = 2 * math.pi * k / 5
            t.sphere("Petal", col, (x + 0.04 + math.cos(a) * 0.3, y + math.sin(a) * 0.3 - 0.05, top), 0.24, u=6, v=4)
        t.sphere("Center", "FFD84A" if col != "FFD04A" else "FF9A3C", (x + 0.04, y - 0.06, top + 0.05), 0.2, u=6, v=4)
    return t


def prop_sign():
    t = Toy("prop_sign", rough=0.5)
    for sx in (-17.0, 17.0):
        t.box("WoodDark", WOOD_D, (sx, 0, 9.5), (2.6, 2.6, 19.0), bevel=0.45)
        t.cyl("Trim", GOLD, (sx, 0, 19.6), 1.9, 0.9, seg=14, r2=1.5, metal=0.4, rough=0.35)
        t.sphere("Glow", "FFE9A0", (sx, 0, 21.2), 1.1, u=12, v=8, emit=1.0)
        t.box("Stone", STONE, (sx, 0, 0.5), (4.2, 4.2, 1.0), bevel=0.3)
    t.box("Board", BLUE, (0, 0, 16.0), (35.0, 1.2, 8.6), bevel=0.4, rough=0.45)
    t.box("Trim", GOLD, (0, -0.1, 20.55), (37.0, 1.7, 1.0), bevel=0.3, metal=0.4, rough=0.35)
    t.box("Trim", GOLD, (0, -0.1, 11.45), (37.0, 1.7, 1.0), bevel=0.3, metal=0.4, rough=0.35)
    for sx in (-17.6, 17.6):
        t.box("Trim", GOLD, (sx, -0.1, 16.0), (1.0, 1.7, 9.0), bevel=0.3, metal=0.4, rough=0.35)
    for sx in (-14.8, 14.8):
        star6(t, "Trim", GOLD_L, (sx, -0.75, 16.0), 1.5, 0.3)
    return t


def prop_gate_pillar():
    t = Toy("prop_gate_pillar", rough=0.5)
    t.box("Stone", STONE_D, (0, 0, 0.5), (3.6, 3.6, 1.0), bevel=0.25)
    t.box("Stone", STONE, (0, 0, 3.6), (2.5, 2.5, 6.4), bevel=0.3)
    t.box("Accent", BLUE, (0, 0, 4.4), (2.62, 2.62, 0.5), bevel=0.12)
    t.box("StoneLight", STONE_L, (0, 0, 7.0), (3.3, 3.3, 0.7), bevel=0.25)
    t.cyl("Trim", GOLD, (0, 0, 7.8), 1.0, 0.5, seg=12, r2=0.7, metal=0.4)
    t.sphere("Glow", "FFE9A0", (0, 0, 8.7), 0.95, u=12, v=8, emit=1.0)
    t.cyl("Trim", GOLD, (0, 0, 9.65), 1.2, 0.6, seg=12, r2=0.15, metal=0.4)
    return t


def prop_padring():
    t = Toy("prop_padring", rough=0.5)
    t.torus("Stone", STONE, (0, 0, 0.25), 6.4, 0.55, seg=36, rseg=8)
    for i in range(12):
        a = 2 * math.pi * i / 12
        t.sphere("Trim", GOLD, (math.cos(a) * 6.4, math.sin(a) * 6.4, 0.82), 0.3, u=8, v=5, metal=0.4)
    for i in range(4):
        a = math.pi / 4 + math.pi / 2 * i
        x, y = math.cos(a) * 7.2, math.sin(a) * 7.2
        t.cyl("StoneLight", STONE_L, (x, y, 0.55), 0.45, 1.1, seg=10)
        t.sphere("Glow", "FFE9A0", (x, y, 1.45), 0.42, u=8, v=5, emit=1.0)
    return t


def prop_balloon():
    t = Toy("prop_balloon", rough=0.25)
    t.sphere("Balloon", "FF5A7A", (0, 0, 1.4), 1.25, u=14, v=10, scale=(1, 1, 1.2))
    t.cyl("Balloon", "FF5A7A", (0, 0, -0.15), 0.18, 0.3, seg=8, r2=0.05)
    t.sphere("Shine", "FFFFFF", (-0.45, -0.7, 2.0), 0.22, u=6, v=4, scale=(0.6, 0.3, 1.0))
    tube(t, "String", "E8E8F0", [(0, 0, -0.3), (0.2, 0, -1.6), (-0.15, 0, -3.0)], 0.03, seg=4)
    return t


def prop_flag():
    t = Toy("prop_flag", rough=0.5)
    t.cyl("Stone", STONE, (0, 0, 0.4), 1.5, 0.8, seg=14, r2=1.2)
    t.cyl("WoodDark", WOOD_D, (0, 0, 7.4), 0.28, 13.2, seg=8, r2=0.2)
    t.sphere("Trim", GOLD, (0, 0, 14.3), 0.55, u=10, v=6, metal=0.4)
    pts_top, pts_bot = [], []
    n = 9
    for i in range(n + 1):
        u = i / n
        x = 0.3 + u * 5.6
        wave = math.sin(u * math.pi * 1.6) * 0.5 * u
        top = 13.3 - u * 0.9
        bot = 10.6 + u * 0.9
        pts_top.append((x, wave, top))
        pts_bot.append((x, wave, bot))
    for i in range(n):
        a, b, c, d = pts_top[i], pts_top[i + 1], pts_bot[i + 1], pts_bot[i]
        t.poly("Accent", RED_FLAG, [(a[0], a[2]), (b[0], b[2]), (c[0], c[2]), (d[0], d[2])], min(a[1], b[1]) - 0.06, max(a[1], b[1]) + 0.06, bevel=0.01, plane="XZ")
    t.box("Trim", GOLD, (0.2, 0.0, 12.0), (0.5, 0.45, 3.2), bevel=0.1, metal=0.4)
    star6(t, "Trim", GOLD_L, (2.6, -0.28, 12.0), 0.7, 0.05)
    return t


def prop_spawnpad():
    t = Toy("prop_spawnpad", rough=0.45)
    t.cyl("Stone", STONE, (0, 0, 0.2), 3.7, 0.4, seg=32, bevel=0.06)
    t.torus("Accent", BLUE, (0, 0, 0.42), 3.1, 0.2, seg=36, rseg=6)
    t.cyl("StoneLight", STONE_L, (0, 0, 0.44), 2.55, 0.06, seg=32)
    t.cyl("Trim", GOLD, (0, 0, 0.47), 0.9, 0.06, seg=20, metal=0.4, rough=0.35)
    for i in range(8):
        a = 2 * math.pi * i / 8 + math.pi / 8
        t.sphere("Trim", GOLD_L, (math.cos(a) * 3.1, math.sin(a) * 3.1, 0.62), 0.16, u=6, v=4, metal=0.4)
    return t


def prop_plaza():
    t = Toy("prop_plaza", rough=0.6)
    R = 95.0
    t.cyl("Stone", STONE, (0, 0, 0.12), R, 0.24, seg=96)
    def ring(r0, r1, z0, z1, label, hexs, seg=64, offset=0.0, step=1):
        for i in range(0, seg, step):
            a0 = 2 * math.pi * i / seg + offset
            a1 = 2 * math.pi * (i + 1) / seg + offset
            am = (a0 + a1) / 2
            pts = [(math.cos(a0) * r0, math.sin(a0) * r0), (math.cos(am) * r0, math.sin(am) * r0), (math.cos(a1) * r0, math.sin(a1) * r0),
                   (math.cos(a1) * r1, math.sin(a1) * r1), (math.cos(am) * r1, math.sin(am) * r1), (math.cos(a0) * r1, math.sin(a0) * r1)]
            t.poly(label, hexs, pts, z0, z1, bevel=0.0)
    ring(86, 94, 0.24, 0.5, "StoneLight", STONE_L, seg=96)
    for i in range(48):
        a0 = 2 * math.pi * i / 48
        a1 = 2 * math.pi * (i + 1) / 48
        am = (a0 + a1) / 2
        pts = [(math.cos(a0) * 70, math.sin(a0) * 70), (math.cos(am) * 70, math.sin(am) * 70), (math.cos(a1) * 70, math.sin(a1) * 70),
               (math.cos(a1) * 85, math.sin(a1) * 85), (math.cos(am) * 85, math.sin(am) * 85), (math.cos(a0) * 85, math.sin(a0) * 85)]
        t.poly("TileA" if i % 2 == 0 else "TileB", "EEDDB0" if i % 2 == 0 else "CFA866", pts, 0.24, 0.4, bevel=0.0)
    ring(56, 68, 0.24, 0.46, "Water", "7CC4FF", seg=96)
    for i in range(32):
        a0 = 2 * math.pi * i / 32
        a1 = 2 * math.pi * (i + 1) / 32
        am = (a0 + a1) / 2
        pts = [(math.cos(a0) * 42, math.sin(a0) * 42), (math.cos(am) * 42, math.sin(am) * 42), (math.cos(a1) * 42, math.sin(a1) * 42),
               (math.cos(a1) * 54, math.sin(a1) * 54), (math.cos(am) * 54, math.sin(am) * 54), (math.cos(a0) * 54, math.sin(a0) * 54)]
        t.poly("Gold" if i % 2 == 0 else "GoldLight", "EBB440" if i % 2 == 0 else "FFD66B", pts, 0.24, 0.44, bevel=0.0)
    ring(22, 40, 0.24, 0.38, "TileA", "EEDDB0", seg=64)
    ring(16.5, 22, 0.24, 0.5, "StoneLight", STONE_L, seg=64)
    t.torus("Trim", GOLD, (0, 0, 0.52), 90.0, 0.35, seg=96, rseg=5, metal=0.4, rough=0.4)
    t.torus("Trim", GOLD, (0, 0, 0.45), 54.8, 0.28, seg=96, rseg=5, metal=0.4, rough=0.4)
    return t


def flower_at(t, x, y, h, col, lean=0.0):
    tube(t, "Stem", "3FA64A", [(x, y, 0), (x + lean * 0.5, y, h * 0.5), (x + lean, y, h)], 0.08, seg=5, joints=False)
    t.sphere("Leaf", "3FA64A", (x + 0.3, y, h * 0.35), 0.24, u=6, v=4, scale=(1.5, 0.4, 0.7))
    top = h + 0.1
    for k in range(5):
        a = 2 * math.pi * k / 5
        t.sphere("Petal", col, (x + lean + math.cos(a) * 0.36, y + math.sin(a) * 0.36 - 0.04, top), 0.29, u=6, v=4)
    t.sphere("Center", "FFD84A" if col != "FFD04A" else "FF9A3C", (x + lean, y - 0.06, top + 0.05), 0.24, u=6, v=4)


def prop_wildflower():
    t = Toy("prop_wildflower", rough=0.5)
    cols = ("FF6B8E", "FFD04A", "B58BFF", "FFFFFF", "5BA8FF", "FF9A3C")
    spots = ((-2.6, -1.2, 2.6, 0.2), (-1.0, 1.6, 3.4, -0.2), (0.4, -1.8, 2.9, 0.1), (1.6, 0.9, 3.8, -0.1), (2.9, -0.8, 2.4, 0.2),
             (-0.2, 0.2, 3.0, 0.0), (-3.0, 1.4, 2.2, -0.2))
    for i, (x, y, h, lean) in enumerate(spots):
        flower_at(t, x, y, h, cols[(i * 5) % 6], lean)
    return t


def prop_pathtile():
    t = Toy("prop_pathtile", rough=0.7)
    t.box("PathBase", "D8C79C", (0, 0, 0.12), (14.0, 10.0, 0.24), bevel=0.05)
    stones = (("E9DABA", -4.3, -3.0), ("DDCBA0", -1.3, -3.2), ("E9DABA", 1.8, -3.0), ("DDCBA0", 4.7, -3.2),
              ("DDCBA0", -4.6, 0.0), ("E9DABA", -1.6, 0.1), ("DDCBA0", 1.4, 0.0), ("E9DABA", 4.4, 0.2),
              ("E9DABA", -4.2, 3.1), ("DDCBA0", -1.2, 3.2), ("E9DABA", 1.9, 3.1), ("DDCBA0", 4.8, 3.0))
    for i, (hx, x, y) in enumerate(stones):
        t.box("Stone" + ("A" if hx == "E9DABA" else "B"), hx, (x, y, 0.26), (2.7, 2.6, 0.2), bevel=0.14)
    for sx in (-6.7, 6.7):
        t.box("Edge", "B9A678", (sx, 0, 0.3), (0.6, 10.0, 0.5), bevel=0.2)
    return t


BUILDERS = {
    "fountain": prop_fountain, "tree": prop_tree, "tree2": prop_tree2, "tree3": prop_tree3, "bush": prop_bush,
    "rock": prop_rock, "bench": prop_bench, "lamp": prop_lamp, "fence": prop_fence, "flowers": prop_flowers,
    "sign": prop_sign, "gate_pillar": prop_gate_pillar, "padring": prop_padring, "balloon": prop_balloon,
    "flag": prop_flag, "spawnpad": prop_spawnpad, "plaza": prop_plaza, "wildflower": prop_wildflower, "pathtile": prop_pathtile,
}

DIRS = {
    "fountain": (0.5, -1.0, 0.55), "sign": (0.2, -1.0, 0.15), "fence": (0.3, -1.0, 0.2), "bench": (0.5, -1.0, 0.35),
    "padring": (0.3, -1.0, 1.2), "balloon": (0.3, -1.0, 0.2), "flag": (0.3, -1.0, 0.25), "wildflower": (0.3, -1.0, 0.5), "pathtile": (0.2, -1.0, 1.4), "plaza": (0.3, -1.0, 1.6), "spawnpad": (0.3, -1.0, 0.7),
}


def build_props(names=None, do_export=False):
    return build_set(BUILDERS, names, do_export, "prop_", 384, DIRS)
