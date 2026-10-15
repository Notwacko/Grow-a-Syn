K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())

BLACK, CHAR, GRAY, NAVY, WHITE = "1C1C24", "30323E", "7C8294", "26396E", "F6F6FA"
GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
SILVER = "D5DAE6"
FUR, FUR_D = "7A4A2C", "5A3420"
VELVET = "14121C"
HAIR = "54382A"
BLUE = "3B72E0"
RED = "D94A4A"


def new(name):
    t = Toy(name, rough=0.55)
    t.marker("Origin", (0, 0, 0), (0.04, 0.04, 0.04))
    return t


def kippah():
    t = new("ofit_kippah")
    rot = (-12, 0, 0)
    dome(t, "Head.Base", NAVY, (0, 0.08, 0.5), 0.52, 0.22, seg=20, rot=rot, steps=4)
    dome(t, "Head.Mid", "E9C34A", (0, 0.08, 0.5), 0.34, 0.26, seg=18, rot=rot, steps=4)
    dome(t, "Head.Top", RED, (0, 0.08, 0.5), 0.18, 0.3, seg=14, rot=rot, steps=3)
    t.torus("Head.Base", NAVY, (0, 0.08, 0.5), 0.5, 0.035, seg=22, rseg=5, rot=rot)
    return t


def kippah_knit():
    t = new("ofit_kippah_knit")
    rot = (-12, 0, 0)
    dome(t, "Head.Base", "EEE8D6", (0, 0.08, 0.5), 0.6, 0.3, seg=20, rot=rot, steps=4)
    t.torus("Head.Mid", BLUE, (0, 0.08, 0.5), 0.58, 0.06, seg=22, rseg=5, rot=rot)
    for i in range(10):
        a = 2 * math.pi * i / 10
        p = Vector((math.cos(a) * 0.3, math.sin(a) * 0.3, 0.2))
        m = Matrix.Rotation(math.radians(-12), 3, 'X')
        q = m @ p
        t.sphere("Head.Top", RED, (q.x, 0.08 + q.y, 0.5 + q.z), 0.07, u=6, v=4)
    t.sphere("Head.Top", RED, (0, 0.14, 0.5 + 0.3 * math.cos(math.radians(12))), 0.09, u=6, v=4)
    return t


def hat(name, brim, crown, height, band_h, dent=True, soft=False):
    t = new(name)
    z0 = 0.46
    t.lathe("Head.Hat", BLACK, (0, 0, z0), [(crown * 0.9, 0.0), (brim, 0.0), (brim + 0.03, 0.05), (brim, 0.1), (crown, 0.12)], seg=34)
    t.lathe("Head.Hat", BLACK, (0, 0, z0), [(crown, 0.0), (crown * 1.03, height * 0.5), (crown * 0.94, height), (crown * (0.7 if dent else 0.8), height + (0.0 if soft else 0.0)), (crown * 0.4, height - (0.12 if dent else 0.0)), (0, height - (0.12 if dent else 0.0))], seg=30)
    t.lathe("Head.Band", GRAY, (0, 0, z0), [(crown * 1.035, 0.08), (crown * 1.05, 0.08 + band_h)], seg=30)
    t.lathe("Head.Band", GRAY, (0, 0, z0), [(crown * 1.05, 0.08 + band_h), (crown * 1.035, 0.08)], seg=30)
    return t


def hat_fedora():
    return hat("ofit_hat_fedora", 1.3, 0.72, 0.78, 0.2)


def hat_wide():
    return hat("ofit_hat_wide", 1.5, 0.78, 0.86, 0.22)


def hat_modest():
    return hat("ofit_hat_modest", 1.0, 0.68, 0.58, 0.16, dent=False, soft=True)


def shtreimel():
    t = new("ofit_shtreimel")
    z0 = 0.48
    t.cyl("Head.FurDark", FUR_D, (0, 0, z0 + 0.34), 0.84, 0.7, seg=28)
    for k, z in enumerate((0.1, 0.32, 0.54)):
        t.torus("Head.Fur", FUR, (0, 0, z0 + z), 0.86 - k * 0.03, 0.22, seg=30, rseg=10)
    t.torus("Head.FurDark", FUR_D, (0, 0, z0 + 0.74), 0.55, 0.16, seg=24, rseg=8)
    t.cyl("Head.Velvet", VELVET, (0, 0, z0 + 0.76), 0.5, 0.1, seg=22)
    return t


def tichel():
    t = new("ofit_tichel")
    rot = (-8, 0, 0)
    dome(t, "Head.Cloth", "5B8FE8", (0, 0.06, 0.26), 0.7, 0.5, seg=22, rot=rot, steps=5)
    t.sphere("Head.Cloth", "5B8FE8", (0, 0.3, 0.0), 0.7, u=14, v=9, scale=(1.0, 0.75, 0.95))
    t.torus("Head.Accent", "9FD0FF", (0, 0.04, 0.3), 0.68, 0.06, seg=24, rseg=5, rot=(-8, 0, 0))
    t.sphere("Head.Cloth", "5B8FE8", (0, 0.72, 0.08), 0.28, u=10, v=6)
    t.box("Head.Accent", "9FD0FF", (0.16, 0.8, -0.3), (0.24, 0.1, 0.62), bevel=0.04, rot=(0, 0, 14))
    t.box("Head.Accent", "9FD0FF", (-0.16, 0.8, -0.28), (0.24, 0.1, 0.5), bevel=0.04, rot=(0, 0, -10))
    return t


def beard():
    t = new("ofit_beard")
    t.sphere("Head.Hair", HAIR, (0, -0.4, -0.5), 0.5, u=12, v=8, scale=(1.0, 0.72, 0.58))
    for sx in (-1, 1):
        t.sphere("Head.Hair", HAIR, (sx * 0.5, -0.28, -0.3), 0.3, u=10, v=6, scale=(0.7, 0.9, 1.1))
        t.sphere("Head.Hair", HAIR, (sx * 0.17, -0.6, -0.22), 0.13, u=8, v=5, scale=(1.5, 0.6, 0.7))
    return t


def peyot():
    t = new("ofit_peyot")
    for sx in (-1, 1):
        pts = []
        for i in range(13):
            u = i / 12
            ang = u * 5.5
            pts.append((sx * (0.66 + math.cos(ang) * 0.07), -0.1 + math.sin(ang) * 0.07, 0.15 - u * 0.75))
        tube(t, "Head.Hair", HAIR, pts, 0.045, seg=6)
    return t


def sleeves(t, label_u="Cloth", cuff=True, shirt=WHITE):
    for side, sx in (("Left", -1), ("Right", 1)):
        t.box(side + "UpperArm." + label_u, NAVY, (0, 0, 0), (1.04, 0.86, 1.3), bevel=0.28)
        t.box(side + "LowerArm." + label_u, NAVY, (0, 0, 0.02), (0.92, 1.0, 1.12), bevel=0.24)
        if cuff:
            t.box(side + "LowerArm.Shirt", shirt, (0, 0, -0.5), (0.86, 0.94, 0.16), bevel=0.05)


def jacket(name, vee, lapel, buttons, hem=True):
    t = new(name)
    t.box("UpperTorso.Cloth", NAVY, (0, 0, 0), (2.02, 1.2, 2.0), bevel=0.4)
    if hem:
        t.box("LowerTorso.Cloth", NAVY, (0, 0, 0.0), (1.8, 1.16, 0.58), bevel=0.2)
    t.poly("UpperTorso.Shirt", WHITE, [(-vee, 1.0), (vee, 1.0), (0, 0.0)], -0.62, -0.57, bevel=0.01, plane="XZ")
    t.lathe("UpperTorso.Shirt", WHITE, (0, -0.02, 1.0), [(0.36, 0.0), (0.36, 0.12)], seg=16)
    t.lathe("UpperTorso.Shirt", WHITE, (0, -0.02, 1.0), [(0.36, 0.12), (0.36, 0.0)], seg=16)
    if lapel:
        for sx in (-1, 1):
            pts = [(sx * vee * 0.95, 1.0), (sx * (vee + 0.46), 0.9), (sx * (vee + 0.24), -0.2), (sx * 0.06, 0.0)]
            t.poly("UpperTorso.ClothDark", "1B2C58", pts, -0.66, -0.58, bevel=0.03, plane="XZ")
    for i in range(buttons):
        t.sphere("UpperTorso.Trim", GOLD, (0, -0.64, -0.1 - i * 0.42), 0.075, u=8, v=5, metal=0.4)
    sleeves(t)
    return t


def jacket_closed():
    return jacket("ofit_jacket_closed", 0.3, True, 3)


def jacket_open():
    return jacket("ofit_jacket_open", 0.78, True, 1)


def tie():
    t = new("ofit_tie")
    t.box("UpperTorso.Tie", BLUE, (0, -0.64, 0.78), (0.24, 0.12, 0.22), bevel=0.05)
    t.poly("UpperTorso.Tie", BLUE, [(-0.11, 0.7), (0.11, 0.7), (0.17, -0.14), (0.0, -0.28), (-0.17, -0.14)], -0.66, -0.6, bevel=0.02, plane="XZ")
    return t


def coat_long():
    t = jacket("ofit_coat_long", 0.18, True, 2, hem=False)
    prof = [(0.94, 0.34), (0.98, 0.1), (1.06, -0.9), (1.18, -1.85)]
    t.lathe("LowerTorso.Cloth", NAVY, (0, 0, 0), prof, seg=32, scale=(1.0, 0.66, 1.0))
    t.lathe("LowerTorso.Cloth", NAVY, (0, 0, 0), [(prof[3][0] * 0.97, prof[3][1]), (prof[0][0] * 0.97, prof[0][1])], seg=32, scale=(1.0, 0.66, 1.0))
    t.lathe("LowerTorso.Accent", GOLD, (0, 0, 0), [(1.17, -1.85), (1.22, -1.85), (1.22, -1.68), (1.165, -1.68)], seg=32, scale=(1.0, 0.66, 1.0))
    t.lathe("LowerTorso.Accent", GOLD, (0, 0, 0), [(1.165, -1.68), (1.22, -1.68), (1.22, -1.85), (1.17, -1.85)], seg=32, scale=(1.0, 0.66, 1.0))
    for z, rr in ((-0.55, 1.03), (-1.05, 1.09), (-1.5, 1.14)):
        t.lathe("LowerTorso.Stripe", SILVER, (0, 0, z), [(rr, 0.0), (rr + 0.03, 0.0), (rr + 0.03, 0.1), (rr, 0.1)], seg=32, scale=(1.0, 0.66, 1.0))
    return t


def gartel():
    t = new("ofit_gartel")
    t.lathe("LowerTorso.Belt", CHAR, (0, 0, 0.12), [(0.9, -0.15), (0.97, -0.15), (0.97, 0.15), (0.9, 0.15)], seg=32, scale=(1.0, 0.66, 1.0))
    t.lathe("LowerTorso.Belt", CHAR, (0, 0, 0.12), [(0.9, 0.15), (0.97, 0.15), (0.97, -0.15), (0.9, -0.15)], seg=32, scale=(1.0, 0.66, 1.0))
    t.box("LowerTorso.Buckle", SILVER, (0.35, -0.66, 0.12), (0.34, 0.08, 0.3), bevel=0.04, metal=0.6, rough=0.3)
    return t


def tzitzit():
    t = new("ofit_tzitzit")
    for sx in (-1, 1):
        for k in range(4):
            tube(t, "LowerTorso.Fringe", WHITE, [(sx * 0.9, -0.3 + k * 0.1, 0.05), (sx * 0.93, -0.3 + k * 0.1, -0.5), (sx * 0.91, -0.28 + k * 0.1, -0.95)], 0.025, seg=5, joints=False)
        t.sphere("LowerTorso.Fringe", WHITE, (sx * 0.9, -0.2, 0.08), 0.08, u=6, v=4)
    return t


def socks():
    t = new("ofit_socks")
    for side in ("Left", "Right"):
        t.cyl(side + "LowerLeg.Sock", WHITE, (0, 0, -0.18), 0.43, 0.85, seg=14)
        t.torus(side + "LowerLeg.Band", "C9D3F0", (0, 0, 0.22), 0.43, 0.04, seg=14, rseg=5)
    return t


def skirt_long():
    t = new("ofit_skirt_long")
    prof = [(0.94, 0.32), (0.98, 0.0), (1.08, -1.0), (1.22, -1.95)]
    t.lathe("LowerTorso.Cloth", NAVY, (0, 0, 0), prof, seg=32, scale=(1.0, 0.68, 1.0))
    t.lathe("LowerTorso.Cloth", NAVY, (0, 0, 0), [(prof[3][0] * 0.97, prof[3][1]), (prof[0][0] * 0.97, prof[0][1])], seg=32, scale=(1.0, 0.68, 1.0))
    t.lathe("LowerTorso.Band", CHAR, (0, 0, 0.25), [(0.93, -0.12), (0.98, -0.12), (0.98, 0.1), (0.93, 0.1)], seg=32, scale=(1.0, 0.68, 1.0))
    return t


def tallit():
    t = new("ofit_tallit")
    for sx in (-1, 1):
        t.box("UpperTorso.Handle", WHITE, (sx * 0.72, 0.0, 1.02), (1.1, 1.3, 0.22), bevel=0.09, rot=(0, -sx * 14, 0))
        t.box("UpperTorso.Handle", WHITE, (sx * 0.64, -0.62, 0.05), (0.62, 0.12, 2.0), bevel=0.05)
        t.box("UpperTorso.Stripe", BLUE, (sx * 0.64, -0.69, -0.62), (0.64, 0.05, 0.14), bevel=0.02)
        t.box("UpperTorso.Stripe", BLUE, (sx * 0.64, -0.69, -0.86), (0.64, 0.05, 0.14), bevel=0.02)
        t.box("UpperTorso.Stripe", BLUE, (sx * 1.05, 0.0, 0.88), (0.2, 1.34, 0.05), bevel=0.02, rot=(0, -sx * 14, 0))
        for k in range(4):
            tube(t, "UpperTorso.Fringe", WHITE, [(sx * (0.46 + k * 0.1), -0.7, -1.0), (sx * (0.46 + k * 0.1), -0.7, -1.4)], 0.022, seg=5, joints=False)
    t.box("UpperTorso.Handle", WHITE, (0, 0.62, 0.05), (1.8, 0.12, 2.0), bevel=0.05)
    t.box("UpperTorso.Stripe", BLUE, (0, 0.69, -0.62), (1.8, 0.05, 0.14), bevel=0.02)
    t.box("UpperTorso.Stripe", BLUE, (0, 0.69, -0.86), (1.8, 0.05, 0.14), bevel=0.02)
    t.lathe("UpperTorso.Atarah", GOLD, (0, -0.02, 1.0), [(0.33, 0.0), (0.4, 0.0), (0.4, 0.14), (0.33, 0.14)], seg=18)
    t.lathe("UpperTorso.Atarah", GOLD, (0, -0.02, 1.0), [(0.33, 0.14), (0.4, 0.14), (0.4, 0.0), (0.33, 0.0)], seg=18)
    return t


BUILDERS = {
    "kippah": kippah, "kippah_knit": kippah_knit, "hat_fedora": hat_fedora, "hat_wide": hat_wide, "hat_modest": hat_modest,
    "shtreimel": shtreimel, "tichel": tichel, "beard": beard, "peyot": peyot, "jacket_closed": jacket_closed,
    "jacket_open": jacket_open, "tie": tie, "coat_long": coat_long, "gartel": gartel, "tzitzit": tzitzit,
    "socks": socks, "skirt_long": skirt_long, "tallit": tallit,
}


def build_outfits(names=None, do_export=False, preview=True):
    out = {}
    for name in (names or list(BUILDERS)):
        reset()
        toy = BUILDERS[name]()
        objs = toy.finish()
        entry = {"parts": len(objs), "tris": tris(objs)}
        if preview:
            render_icon(objs, "ofit_" + name, size=384, direction=(0.5, -1.0, 0.45), pad=1.08)
        if do_export:
            entry.update(export("ofit_" + name, objs))
        out[name] = entry
    return out
