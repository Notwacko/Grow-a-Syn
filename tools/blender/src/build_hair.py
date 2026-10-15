K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())

HAIR = "5A3A28"
TIE = "E8453C"


def new(name, rough=0.7):
    t = Toy(name, rough=rough)
    t.marker("Origin", (0, 0, 0), (0.04, 0.04, 0.04))
    return t


def cap(t, color):
    t.box("Head.Hair", color, (0, 0.02, 0.55), (1.34, 1.34, 0.34), bevel=0.13)
    t.box("Head.Hair", color, (0, 0.6, 0.12), (1.34, 0.2, 1.06), bevel=0.09)
    for sx in (-1, 1):
        t.box("Head.Hair", color, (sx * 0.63, 0.08, 0.24), (0.14, 1.04, 0.7), bevel=0.06)
    t.box("Head.Hair", color, (0, -0.6, 0.47), (1.34, 0.18, 0.3), bevel=0.08)
    for sx, sz in ((-0.4, 0.34), (-0.13, 0.38), (0.14, 0.34), (0.42, 0.38)):
        t.sphere("Head.Hair", color, (sx, -0.64, sz), 0.15, u=8, v=5)


def hair_short():
    t = new("ofit_hair_short")
    cap(t, HAIR)
    return t


def hair_long():
    t = new("ofit_hair_long")
    cap(t, HAIR)
    t.box("Head.Hair", HAIR, (0, 0.5, -0.5), (1.34, 0.36, 1.9), bevel=0.14)
    t.sphere("Head.Hair", HAIR, (0, 0.5, -1.42), 1.0, u=12, v=8, scale=(0.67, 0.2, 0.2))
    for sx in (-1, 1):
        t.box("Head.Hair", HAIR, (sx * 0.66, 0.12, -0.32), (0.17, 0.6, 1.3), bevel=0.07)
    return t


def hair_bun():
    t = new("ofit_hair_bun")
    cap(t, HAIR)
    t.sphere("Head.Hair", HAIR, (0, 0.38, 0.74), 0.3, u=12, v=8)
    t.torus("Head.Tie", TIE, (0, 0.38, 0.5), 0.2, 0.045, seg=14, rseg=5)
    return t


def hair_curly():
    t = new("ofit_hair_curly", 0.8)
    for i in range(10):
        a = 2 * math.pi * i / 10
        t.sphere("Head.Hair", HAIR, (0.62 * math.cos(a), 0.62 * math.sin(a) + 0.04, 0.12), 0.28, u=10, v=7)
    for i in range(8):
        a = 2 * math.pi * i / 8 + 0.2
        t.sphere("Head.Hair", HAIR, (0.5 * math.cos(a), 0.5 * math.sin(a) + 0.04, 0.42), 0.33, u=10, v=7)
    for i in range(5):
        a = 2 * math.pi * i / 5
        t.sphere("Head.Hair", HAIR, (0.26 * math.cos(a), 0.26 * math.sin(a) + 0.04, 0.64), 0.33, u=10, v=7)
    t.sphere("Head.Hair", HAIR, (0, 0.04, 0.74), 0.34, u=10, v=7)
    for sx in (-0.36, 0.0, 0.36):
        t.sphere("Head.Hair", HAIR, (sx, 0.6, -0.1), 0.3, u=10, v=7)
    return t


def hair_pony():
    t = new("ofit_hair_pony")
    cap(t, HAIR)
    pts = [(0, 0.56, 0.36), (0, 0.86, 0.16), (0, 0.96, -0.3), (0, 0.84, -0.78)]
    tube(t, "Head.Hair", HAIR, pts, 0.17, seg=8, r2=None)
    t.sphere("Head.Hair", HAIR, (0, 0.84, -0.84), 0.15, u=8, v=5)
    t.torus("Head.Tie", TIE, (0, 0.6, 0.33), 0.17, 0.04, seg=12, rseg=5, rot=(60, 0, 0))
    return t


BUILDERS = {
    "hair_short": hair_short,
    "hair_long": hair_long,
    "hair_bun": hair_bun,
    "hair_curly": hair_curly,
    "hair_pony": hair_pony,
}


def ghost_head():
    t = Toy("ghost", rough=0.8)
    t.box("Ghost", "8D99B8", (0, 0, 0), (1.2, 1.2, 1.2), bevel=0.25)
    for sx in (-1, 1):
        t.sphere("GhostEye", "3A4256", (sx * 0.27, -0.6, 0.1), 0.07, u=8, v=5)
    return t.finish()


def build_hair(names=None, do_export=True, preview=False):
    out = {}
    for name in (names or list(BUILDERS)):
        reset()
        objs = BUILDERS[name]().finish()
        mn, mx = bounds(objs)
        entry = {"tris": tris(objs), "min": [round(v, 2) for v in mn], "max": [round(v, 2) for v in mx]}
        if do_export:
            entry.update(export("ofit_" + name, objs))
        if preview:
            ghost_head()
            render_icon(objs, "ofit_" + name, size=384, direction=(0.9, -1.0, 0.5), pad=1.2)
        out[name] = entry
    return out
