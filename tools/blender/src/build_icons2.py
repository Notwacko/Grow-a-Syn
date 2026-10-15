K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "build_icons.py").read())
exec(open(K + "toylib.py").read())

PINK = "FF7AA8"
TEAL = "34C3C3"
NAVY = "26396E"


def icon_paw():
    t = Toy("paw", rough=0.45)
    t.sphere("Pad", ORANGE, (0, 0, -0.3), 1.0, scale=(1.2, 0.7, 0.95))
    for x, z, r in ((-1.15, 0.45, 0.4), (-0.42, 1.05, 0.43), (0.42, 1.05, 0.43), (1.15, 0.45, 0.4)):
        t.sphere("Toe", "FFB86B", (x, 0, z), r, scale=(1, 0.7, 1.2))
    t.sphere("Shine", "FFD9A8", (-0.35, -0.55, -0.1), 0.2, scale=(2, 0.3, 1))
    return t


def icon_wardrobe():
    t = Toy("wardrobe", rough=0.5)
    t.torus("Hook", GOLD, (0, 0, 1.75), 0.26, 0.07, seg=18, rseg=6, rot=(90, 0, 0))
    t.cyl("Neck", GOLD, (0, 0, 1.4), 0.07, 0.4, seg=8)
    tube(t, "Bar", GOLD, [(-1.45, 0, 0.5), (0, 0, 1.2), (1.45, 0, 0.5), (-1.45, 0, 0.5)], 0.075, seg=8)
    t.box("Cloth", BLUE, (0, 0.05, -0.35), (2.5, 0.22, 1.7), bevel=0.1)
    for x in (-0.85, 0.85):
        t.box("Stripe", WHITE, (x, -0.07, -0.25), (0.22, 0.05, 1.3), bevel=0.02)
    for x in (-0.95, -0.75, -0.55, 0.55, 0.75, 0.95):
        t.box("Fringe", WHITE, (x, 0.0, -1.35), (0.07, 0.07, 0.5), bevel=0.02)
    return t


def icon_quest():
    t = Toy("quest", rough=0.5)
    t.box("Paper", CREAM, (0, 0, 0), (1.9, 0.14, 2.3), bevel=0.05)
    t.cyl("RollTop", "E8D3A0", (0, 0, 1.2), 0.22, 2.1, seg=16, rot=(0, 90, 0))
    t.cyl("RollBottom", "E8D3A0", (0, 0, -1.2), 0.22, 2.1, seg=16, rot=(0, 90, 0))
    for z in (0.65, 0.2, -0.25):
        t.box("Line", "C9B27E", (0.18, -0.09, z), (1.0, 0.04, 0.12), bevel=0.02)
    t.poly("Check", GREEN, [(-0.78, 0.3), (-0.6, 0.45), (-0.45, 0.12), (-0.05, 0.62), (0.1, 0.48), (-0.45, -0.18)], -0.12, -0.04, bevel=0.03, plane="XZ")
    return t


def icon_book():
    t = Toy("book", rough=0.5)
    t.box("Cover", PURPLE, (0, 0.1, 0), (1.9, 0.62, 2.4), bevel=0.12)
    t.box("Pages", "FFF6E0", (0.12, -0.0, 0), (1.7, 0.5, 2.2), bevel=0.05)
    t.box("Cover2", PURPLE_D, (0, -0.28, 0), (1.9, 0.12, 2.4), bevel=0.06)
    t.box("Spine", PURPLE_D, (-0.95, 0.1, 0), (0.18, 0.68, 2.4), bevel=0.08)
    star6(t, "Star", GOLD, (0.0, -0.37, 0.15), 0.5, 0.06, plane="XZ")
    t.box("Band", GOLD, (0.0, -0.35, -0.82), (1.1, 0.05, 0.14), bevel=0.02)
    return t


def star_pts(r_out, r_in, n=5, rot=90):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180 / n)
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def icon_star():
    t = Toy("star", rough=0.3)
    t.poly("Star", GOLD, star_pts(1.6, 0.72), -0.3, 0.3, bevel=0.14, plane="XZ", emit=0.12)
    t.poly("Shine", GOLD_L, star_pts(1.0, 0.45), -0.34, -0.29, bevel=0.01, plane="XZ")
    return t


def icon_gift():
    t = Toy("gift", rough=0.45)
    t.box("Box", RED, (0, 0, 0), (2.0, 2.0, 1.5), bevel=0.1)
    t.box("Lid", RED_D, (0, 0, 0.95), (2.2, 2.2, 0.45), bevel=0.08)
    t.box("RibbonV", GOLD, (0, 0, 0.1), (0.4, 2.05, 1.55), bevel=0.04)
    t.box("RibbonH", GOLD, (0, 0, 0.1), (2.05, 0.4, 1.55), bevel=0.04)
    t.torus("BowL", GOLD, (-0.5, 0, 1.4), 0.38, 0.1, seg=18, rseg=6, rot=(90, 0, 30))
    t.torus("BowR", GOLD, (0.5, 0, 1.4), 0.38, 0.1, seg=18, rseg=6, rot=(90, 0, -30))
    t.sphere("Knot", GOLD_D, (0, 0, 1.25), 0.2)
    return t


def icon_wheel():
    t = Toy("wheel", rough=0.4)
    cols = [RED, ORANGE, GOLD, GREEN, TEAL, BLUE, PURPLE, PINK]
    n = len(cols)
    for i, c in enumerate(cols):
        a0 = math.radians(i * 360 / n + 90)
        a1 = math.radians((i + 1) * 360 / n + 90)
        pts = [(0, 0), (1.55 * math.cos(a0), 1.55 * math.sin(a0)), (1.55 * math.cos((a0 + a1) / 2), 1.55 * math.sin((a0 + a1) / 2)), (1.55 * math.cos(a1), 1.55 * math.sin(a1))]
        t.poly("Slice", c, pts, -0.18, 0.18, bevel=0.03, plane="XZ")
    t.torus("Rim", GOLD_D, (0, 0, 0), 1.6, 0.12, seg=36, rseg=8, rot=(90, 0, 0))
    t.cyl("Hub", GOLD, (0, -0.2, 0), 0.34, 0.14, seg=20, rot=(90, 0, 0))
    t.poly("Pointer", WHITE, [(-0.2, 1.95), (0.2, 1.95), (0, 1.4)], -0.14, 0.14, bevel=0.03, plane="XZ")
    return t


def icon_trophy():
    t = Toy("trophy", rough=0.28)
    t.lathe("Cup", GOLD, (0, 0, 0.1), [(0, 0), (0.45, 0.0), (0.4, 0.4), (0.95, 1.5), (1.05, 1.9), (0, 1.9)], seg=28, metal=0.2)
    t.torus("HandleL", GOLD_D, (-1.0, 0, 1.3), 0.4, 0.09, seg=20, rseg=6, rot=(90, 0, 0))
    t.torus("HandleR", GOLD_D, (1.0, 0, 1.3), 0.4, 0.09, seg=20, rseg=6, rot=(90, 0, 0))
    t.cyl("Stem", GOLD_D, (0, 0, -0.1), 0.2, 0.5, seg=14)
    t.box("Base", WOOD_D, (0, 0, -0.55), (1.5, 0.9, 0.4), bevel=0.08)
    t.box("Plate", GOLD, (0, -0.47, -0.55), (0.7, 0.05, 0.2), bevel=0.02)
    t.poly("Star", WHITE, star_pts(0.4, 0.18), -0.04, 0.04, bevel=0.01, plane="XZ")
    return t


def icon_gear():
    t = Toy("gear", rough=0.4)
    t.cyl("Body", "9AA5B8", (0, 0, 0), 1.2, 0.5, seg=32, rot=(90, 0, 0), bevel=0.05)
    for i in range(8):
        a = math.radians(i * 45)
        t.box("Tooth", "9AA5B8", (math.cos(a) * 1.35, 0, math.sin(a) * 1.35), (0.55, 0.5, 0.45), rot=(0, -math.degrees(a), 0), bevel=0.05)
    t.cyl("Hole", "5E6A80", (0, -0.27, 0), 0.5, 0.1, seg=24, rot=(90, 0, 0))
    t.torus("Ring", "C4CEDD", (0, -0.26, 0), 0.9, 0.05, seg=28, rseg=6, rot=(90, 0, 0))
    return t


def icon_heart():
    t = Toy("heart", rough=0.3)
    t.sphere("L", RED, (-0.62, 0, 0.45), 0.85)
    t.sphere("R", RED, (0.62, 0, 0.45), 0.85)
    t.cyl("Tip", RED, (0, 0, -0.45), 1.3, 1.5, seg=24, r2=0.0, rot=(180, 0, 0))
    t.sphere("Shine", "FFB3C0", (-0.85, -0.6, 0.7), 0.22, scale=(1, 0.3, 1.6))
    return t


def icon_calendar():
    t = Toy("calendar", rough=0.45)
    t.box("Page", WHITE, (0, 0, -0.15), (2.2, 0.3, 2.2), bevel=0.1)
    t.box("Head", RED, (0, -0.02, 0.85), (2.2, 0.34, 0.6), bevel=0.08)
    for x in (-0.6, 0.6):
        t.cyl("Ring", "6E7A90", (x, 0, 1.25), 0.1, 0.5, seg=10, rot=(90, 0, 0))
    for row in range(2):
        for col in range(3):
            t.box("Day", "D6DDEA", (-0.6 + col * 0.6, -0.17, 0.2 - row * 0.55), (0.4, 0.05, 0.36), bevel=0.02)
    t.poly("Check", GREEN, [(-0.2, -0.95), (-0.05, -0.8), (0.1, -1.05), (0.5, -0.6), (0.65, -0.72), (0.1, -1.35)], -0.2, -0.1, bevel=0.03, plane="XZ")
    return t


def icon_flame():
    t = Toy("flame", rough=0.3)
    t.lathe("Outer", ORANGE, (0, 0, -0.2), [(0, -0.9), (0.62, -0.55), (0.8, 0.1), (0.5, 0.9), (0.18, 1.5), (0, 1.9)], seg=20, scale=(1, 0.4, 1), emit=0.2)
    t.lathe("Mid", GOLD, (0, -0.16, -0.35), [(0, -0.7), (0.42, -0.4), (0.5, 0.1), (0.28, 0.7), (0, 1.1)], seg=18, scale=(1, 0.4, 1), emit=0.25)
    t.lathe("Core", "FFF3B0", (0, -0.3, -0.5), [(0, -0.5), (0.26, -0.3), (0.28, 0.1), (0.1, 0.5), (0, 0.7)], seg=16, scale=(1, 0.4, 1), emit=0.3)
    return t


def icon_legacy():
    t = Toy("legacy", rough=0.5)
    t.cyl("Trunk", WOOD, (0, 0, 0.2), 0.2, 1.4, seg=12, r2=0.32)
    for x, y, z, r, c in ((0, 0, 1.6, 0.95, GREEN_D), (-0.7, 0.05, 1.2, 0.7, GREEN), (0.7, -0.05, 1.2, 0.7, GREEN), (0.0, -0.3, 1.9, 0.6, GREEN_L)):
        t.sphere("Leaves", c, (x, y, z), r)
    t.cyl("Ground", GREEN, (0, 0, -0.55), 1.2, 0.2, seg=24, bevel=0.04)
    t.poly("Star", GOLD, star_pts(0.38, 0.17), -0.06, 0.06, bevel=0.02, plane="XZ")
    t.sphere("Fruit", GOLD, (-0.5, -0.55, 1.25), 0.14)
    t.sphere("Fruit", GOLD, (0.55, -0.5, 1.5), 0.14)
    return t


def icon_gem():
    t = Toy("gem", rough=0.2)
    t.lathe("Crown", "9B5BFF", (0, 0, 0), [(0, -1.1), (0.55, -0.3), (1.1, 0.35), (0.8, 0.8), (0, 0.8)], seg=8, smooth=False, metal=0.15)
    t.lathe("Table", "C9A2FF", (0, 0, 0.8), [(0, 0.0), (0.8, 0.0)], seg=8, smooth=False)
    t.poly("Shine", WHITE, [(-0.5, 0.55), (-0.2, 0.55), (-0.45, 0.2)], -0.62, -0.58, bevel=0.01, plane="XZ")
    return t


def icon_heartpaw():
    t = Toy("hatch", rough=0.35)
    t.sphere("Egg", "FFF6E0", (0, 0, 0), 1.0, scale=(0.8, 0.8, 1.05))
    for x, z, r, c in ((-0.35, 0.35, 0.2, PINK), (0.4, 0.1, 0.18, TEAL), (0.0, -0.4, 0.22, GOLD), (-0.45, -0.25, 0.14, BLUE), (0.35, 0.6, 0.14, ORANGE)):
        t.sphere("Spot", c, (x, -0.7, z), r, scale=(1, 0.35, 1))
    t.sphere("Shine", WHITE, (-0.4, -0.65, 0.7), 0.14, scale=(1, 0.3, 1.8))
    return t


NEW_ICONS = {
    "paw": icon_paw, "wardrobe": icon_wardrobe, "quest": icon_quest, "book": icon_book, "star": icon_star,
    "gift": icon_gift, "wheel": icon_wheel, "trophy": icon_trophy, "gear": icon_gear, "heart": icon_heart,
    "calendar": icon_calendar, "flame": icon_flame, "legacy": icon_legacy, "gem": icon_gem, "egg": icon_heartpaw,
}


def build_new(names=None, direction=(0.2, -1.0, 0.3)):
    out = {}
    for name in (names or list(NEW_ICONS)):
        reset()
        objs = NEW_ICONS[name]().finish()
        out[name] = render_icon(objs, "icon_" + name, size=256, direction=direction, pad=1.0)
    return out
