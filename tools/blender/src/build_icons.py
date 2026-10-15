K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "kit2.py").read())

GOLD, GOLD_D, GOLD_L = "FFC93C", "E39A12", "FFE48A"
RED, RED_D = "F2546B", "C93351"
GREEN, GREEN_D, GREEN_L = "56C75A", "2E9A3C", "9BEA7A"
BLUE, BLUE_D = "4C9BFF", "2A6FD6"
PURPLE, PURPLE_D = "A878FF", "7A4FD0"
ORANGE, ORANGE_D = "FF9A3C", "E0701A"
WOOD, WOOD_D, WOOD_L = "B97A45", "8A5530", "D9A066"
CREAM, WHITE = "FFF1D0", "FFFFFF"
INK = "3A3A55"


def coin(t, c=(0, 0, 0), r=1.0, h=0.34):
    t.cyl("Coin", GOLD, c, r, h, seg=40, rot=(90, 0, 0), bevel=0.06, metal=0.15)
    t.torus("Rim", GOLD_D, c, r * 0.93, 0.07, seg=40, rot=(90, 0, 0))
    t.cyl("Face", GOLD_L, (c[0], c[1] - h * 0.5 - 0.01, c[2]), r * 0.74, 0.06, seg=40, rot=(90, 0, 0))
    t.box("Mark", GOLD_D, (c[0], c[1] - h * 0.5 - 0.06, c[2]), (r * 0.34, 0.06, r * 0.34), rot=(0, 45, 0), bevel=0.02)


def icon_coin():
    t = Toy("coin", rough=0.32)
    coin(t)
    return t


def icon_coins():
    t = Toy("coins", rough=0.32)
    for i in range(4):
        t.cyl("Coin", GOLD, (0, 0, i * 0.34), 1.0, 0.32, seg=36, bevel=0.05, metal=0.15)
        t.torus("Rim", GOLD_D, (0, 0, i * 0.34 + 0.16), 0.94, 0.05, seg=36)
    t.cyl("Top", GOLD_L, (0, 0, 3 * 0.34 + 0.17), 0.7, 0.04, seg=36)
    return t


def icon_basket():
    t = Toy("basket", rough=0.5)
    t.lathe("Body", WOOD, (0, 0, 0), [(0, 0), (0.78, 0), (0.95, 0.12), (1.15, 1.0), (0, 1.0)], seg=28)
    for z, r in ((0.3, 0.9), (0.62, 1.03), (0.95, 1.14)):
        t.torus("Weave", WOOD_D, (0, 0, z), r, 0.055, seg=32)
    t.torus("Rim", WOOD_L, (0, 0, 1.0), 1.15, 0.1, seg=32)
    t.torus("Handle", WOOD_L, (0, 0, 1.0), 1.1, 0.075, seg=32, rot=(90, 0, 0))
    for (x, y, z, h) in ((-0.45, 0.2, 1.2, RED), (0.35, 0.3, 1.25, "A64BE0"), (0.0, -0.4, 1.3, GOLD), (0.55, -0.3, 1.15, GREEN)):
        t.sphere("Fruit", h, (x, y, z), 0.42)
    return t


def icon_seed():
    t = Toy("seed", rough=0.5)
    t.box("Packet", CREAM, (0, 0, 0), (1.5, 0.34, 2.1), bevel=0.1)
    t.box("Fold", "EAD8AA", (0, 0, 1.0), (1.5, 0.4, 0.28), bevel=0.06)
    t.box("Label", GREEN, (0, -0.19, -0.1), (1.2, 0.06, 1.2), bevel=0.05)
    t.cyl("Stem", GREEN_D, (0, -0.24, -0.35), 0.06, 0.7, seg=10, rot=(0, 0, 0))
    t.sphere("Leaf", GREEN_L, (-0.28, -0.26, 0.05), 0.27, scale=(1.5, 0.3, 0.8), rot=(0, -30, 0))
    t.sphere("Leaf", GREEN_L, (0.28, -0.26, 0.05), 0.27, scale=(1.5, 0.3, 0.8), rot=(0, 30, 0))
    t.sphere("Dot", "8A5530", (0, -0.24, -0.62), 0.14)
    return t


def icon_shop():
    t = Toy("shop", rough=0.45)
    t.poly("Bag", RED, [(-1.0, 0), (1.0, 0), (0.8, 2.0), (-0.8, 2.0)], -0.45, 0.45, bevel=0.1, plane="XZ")
    t.box("Band", RED_D, (0, 0, 1.82), (1.78, 0.98, 0.3), bevel=0.06)
    t.torus("Handle", GOLD, (0, 0, 2.0), 0.55, 0.075, seg=28, rot=(90, 0, 0))
    t.cyl("Star", GOLD, (0, -0.47, 0.9), 0.32, 0.06, seg=5, rot=(90, 0, 0))
    t.sphere("Shine", "FF9AA8", (-0.5, -0.46, 1.2), 0.12, scale=(1, 0.3, 2.4))
    return t


def icon_backpack():
    t = Toy("backpack", rough=0.5)
    t.sphere("Body", ORANGE, (0, 0, 1.0), 1.0, scale=(0.95, 0.62, 1.2))
    t.box("Pocket", ORANGE_D, (0, -0.55, 0.5), (1.2, 0.4, 0.85), bevel=0.16)
    t.box("Flap", "FFB566", (0, -0.35, 1.5), (1.2, 0.34, 0.55), bevel=0.14)
    t.cyl("Buckle", GOLD, (0, -0.55, 1.42), 0.15, 0.08, seg=14, rot=(90, 0, 0))
    t.torus("Loop", ORANGE_D, (0, 0.0, 2.15), 0.3, 0.07, seg=18, rot=(90, 0, 0))
    return t


def icon_land():
    t = Toy("land", rough=0.5)
    t.cyl("Grass", GREEN, (0, 0, 0), 1.45, 0.34, seg=36, bevel=0.06)
    t.cyl("Soil", WOOD_D, (0, 0, -0.18), 1.4, 0.12, seg=36)
    t.cyl("Trunk", WOOD, (0, 0, 0.75), 0.18, 1.1, seg=12, r2=0.26)
    for (x, y, z, r, h) in ((0, 0, 1.75, 0.82, GREEN_D), (-0.5, 0.1, 1.45, 0.62, GREEN), (0.5, -0.1, 1.5, 0.62, GREEN), (0.05, -0.3, 1.95, 0.55, GREEN_L)):
        t.sphere("Leaves", h, (x, y, z), r)
    t.sphere("Apple", RED, (-0.4, -0.55, 1.5), 0.15)
    t.sphere("Apple", RED, (0.45, -0.45, 1.85), 0.15)
    return t


def icon_upgrade():
    t = Toy("upgrade", rough=0.38)
    pts = [(0, 1.6), (1.15, 0.2), (0.45, 0.2), (0.45, -1.3), (-0.45, -1.3), (-0.45, 0.2), (-1.15, 0.2)]
    t.poly("Arrow", GREEN, pts, -0.3, 0.3, bevel=0.14, plane="XZ")
    t.poly("Shine", GREEN_L, [(-0.2, 1.0), (-0.65, 0.3), (-0.2, 0.3)], -0.33, -0.28, bevel=0.01, plane="XZ")
    return t


def icon_puzzle():
    t = Toy("puzzle", rough=0.38)
    t.box("Piece", GOLD, (0, 0, 0), (2.0, 0.55, 2.0), bevel=0.14)
    t.sphere("Knob", GOLD, (0, 0, 1.15), 0.42, scale=(1, 0.55, 1))
    t.sphere("Knob", GOLD, (1.15, 0, 0), 0.42, scale=(1, 0.55, 1))
    t.sphere("Hole", GOLD_D, (-1.0, -0.2, 0), 0.38, scale=(1, 0.5, 1))
    t.sphere("Hole", GOLD_D, (0, -0.2, -1.0), 0.38, scale=(1, 0.5, 1))
    t.sphere("Shine", GOLD_L, (-0.5, -0.29, 0.5), 0.2, scale=(2, 0.2, 1))
    return t


def icon_bolt():
    t = Toy("bolt", rough=0.3)
    pts = [(0.35, 1.7), (-0.9, -0.15), (-0.05, -0.15), (-0.4, -1.7), (0.95, 0.35), (0.1, 0.35), (0.8, 1.7)]
    t.poly("Bolt", GOLD, pts, -0.28, 0.28, bevel=0.1, plane="XZ", emit=0.15)
    t.poly("Shine", GOLD_L, [(0.3, 1.45), (-0.5, 0.0), (-0.05, 0.0)], -0.31, -0.27, bevel=0.01, plane="XZ")
    return t


def icon_synagogue():
    t = Toy("synagogue", rough=0.5)
    t.box("Base", "F6EBCB", (0, 0, 0.75), (2.7, 1.9, 1.5), bevel=0.1)
    t.poly("Roof", BLUE, [(-1.55, 1.45), (1.55, 1.45), (0, 2.5)], -1.1, 1.1, bevel=0.07, plane="XZ")
    t.cyl("Drum", "F6EBCB", (0, 0, 2.55), 0.5, 0.4, seg=20)
    t.sphere("Dome", GOLD, (0, 0, 2.78), 0.52, scale=(1, 1, 0.9))
    t.box("Door", WOOD, (0, -0.98, 0.55), (0.7, 0.1, 1.1), bevel=0.05)
    t.cyl("Arch", WOOD, (0, -0.98, 1.1), 0.35, 0.1, seg=18, rot=(90, 0, 0))
    t.box("Win", "9FD8FF", (-0.95, -0.98, 0.85), (0.42, 0.08, 0.6), bevel=0.04)
    t.box("Win", "9FD8FF", (0.95, -0.98, 0.85), (0.42, 0.08, 0.6), bevel=0.04)
    t.cyl("Star", GOLD, (0, -1.04, 1.8), 0.18, 0.05, seg=6, rot=(90, 0, 0))
    return t


def icon_sun():
    t = Toy("sun", rough=0.3)
    t.sphere("Sun", GOLD, (0, 0, 0), 0.95, emit=0.25)
    for i in range(10):
        a = math.radians(i * 36)
        t.box("Ray", GOLD_D, (math.cos(a) * 1.5, 0, math.sin(a) * 1.5), (0.22, 0.2, 0.62), rot=(0, -math.degrees(a) + 90, 0), bevel=0.05)
    t.sphere("Shine", GOLD_L, (-0.3, -0.8, 0.35), 0.25, scale=(1, 0.3, 1))
    return t


def icon_rain():
    t = Toy("rain", rough=0.4)
    for (x, z, r) in ((-0.7, 0.2, 0.7), (0.1, 0.55, 0.9), (0.85, 0.15, 0.62)):
        t.sphere("Cloud", "9DB4D6", (x, 0, z), r)
    t.box("Cloud", "9DB4D6", (0.05, 0, -0.15), (2.4, 1.0, 0.8), bevel=0.4)
    for x in (-0.8, 0.0, 0.8):
        t.sphere("Drop", BLUE, (x, -0.1, -1.0), 0.17, scale=(0.7, 0.7, 1.6))
        t.sphere("Drop", BLUE, (x + 0.3, -0.1, -1.55), 0.15, scale=(0.7, 0.7, 1.6))
    return t


def icon_clock():
    t = Toy("clock", rough=0.35)
    t.cyl("Case", PURPLE, (0, 0, 0), 1.25, 0.5, seg=36, rot=(90, 0, 0), bevel=0.08)
    t.cyl("Face", WHITE, (0, -0.27, 0), 1.0, 0.06, seg=36, rot=(90, 0, 0))
    t.box("HandA", INK, (0, -0.34, 0.32), (0.12, 0.05, 0.7), bevel=0.02)
    t.box("HandB", RED, (0.3, -0.34, 0), (0.6, 0.05, 0.1), bevel=0.02)
    t.cyl("Pin", GOLD, (0, -0.37, 0), 0.12, 0.06, seg=14, rot=(90, 0, 0))
    t.cyl("Knob", PURPLE_D, (0, 0, 1.45), 0.22, 0.4, seg=16)
    t.box("Tick", INK, (0, -0.31, 0.88), (0.08, 0.04, 0.16), bevel=0.01)
    t.box("Tick", INK, (0.88, -0.31, 0), (0.16, 0.04, 0.08), bevel=0.01)
    t.box("Tick", INK, (-0.88, -0.31, 0), (0.16, 0.04, 0.08), bevel=0.01)
    t.box("Tick", INK, (0, -0.31, -0.88), (0.08, 0.04, 0.16), bevel=0.01)
    return t


def icon_lock():
    t = Toy("lock", rough=0.35)
    t.box("Body", GOLD, (0, 0, 0), (1.8, 0.9, 1.4), bevel=0.2)
    t.torus("Shackle", "C8CCD8", (0, 0, 0.7), 0.55, 0.14, seg=28, rot=(90, 0, 0), metal=0.6)
    t.cyl("Hole", INK, (0, -0.48, 0.05), 0.18, 0.06, seg=16, rot=(90, 0, 0))
    t.box("Slot", INK, (0, -0.48, -0.3), (0.12, 0.06, 0.4), bevel=0.01)
    return t


def icon_people():
    t = Toy("people", rough=0.45)
    for (x, y, body, skin) in ((-0.65, 0.2, BLUE, "F2C79B"), (0.65, 0.2, GREEN, "C98E5B"), (0.0, -0.35, ORANGE, "FFD9B0")):
        t.sphere("Head", skin, (x, y, 1.5), 0.42)
        t.sphere("Body", body, (x, y, 0.55), 0.62, scale=(1, 0.8, 1.05))
    t.sphere("Kippah", "2A3F7A", (0.0, -0.35, 1.78), 0.26, scale=(1, 1, 0.5))
    return t


ICONS_LIST = {
    "coin": icon_coin, "coins": icon_coins, "basket": icon_basket, "seed": icon_seed, "shop": icon_shop,
    "backpack": icon_backpack, "land": icon_land, "upgrade": icon_upgrade, "puzzle": icon_puzzle,
    "bolt": icon_bolt, "synagogue": icon_synagogue, "sun": icon_sun, "rain": icon_rain, "clock": icon_clock,
    "lock": icon_lock, "people": icon_people,
}


def build(names=None, direction=(0.45, -1.0, 0.55)):
    out = {}
    for name in (names or list(ICONS_LIST)):
        reset()
        toy = ICONS_LIST[name]()
        objs = toy.finish()
        out[name] = render_icon(objs, "icon_" + name, size=256, direction=direction, pad=1.0)
    return out
