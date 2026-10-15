K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())
import random

EYE, SHINE, MOUTH, CHEEK = "23233A", "FFFFFF", "8A3B3B", "FF9AA2"
WHITE, BLACK = "FFFFFF", "2B2B35"
PINK = "FFB3C0"
SHINY = dict(rough=0.18, metal=0.25)


def new_pet(name):
    return Toy(name, rough=0.5)


def E(t, label, hexs, c, rad, rot=(0, 0, 0), u=None, v=None, **kw):
    if u is None:
        big = max(rad)
        u, v = (12, 8) if big >= 0.7 else ((10, 6) if big >= 0.3 else (8, 5))
    t.sphere(label, hexs, c, 1.0, u=u, v=v, scale=rad, rot=rot, **kw)


def edeg(M):
    e = M.to_euler('XYZ')
    return (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z))


def align_z(pos, normal, spin=0.0):
    q = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized())
    M = q.to_matrix().to_4x4()
    if spin:
        M = M @ Matrix.Rotation(math.radians(spin), 4, 'Z')
    return Matrix.Translation(Vector(pos)) @ M


def head_y(c, rad, x, dz):
    k = 1 - (x / rad[0]) ** 2 - (dz / rad[2]) ** 2
    return c[1] - rad[1] * math.sqrt(max(k, 0.03))


def face(t, c, rad, ex=0.4, ez=0.08, es=0.17, cz=-0.3, sw=0.26, cheeks=0.66, nose=None):
    rx, ry, rz = rad
    for sx in (-1, 1):
        x = sx * ex * rx
        dz = ez * rz
        y = head_y(c, rad, x, dz) + 0.03
        er = es * rx
        E(t, "Eye", EYE, (x, y, c[2] + dz), (er * 0.8, er * 0.55, er * 1.25), u=10, v=7)
        E(t, "EyeShine", SHINE, (x - er * 0.3, y - er * 0.44, c[2] + dz + er * 0.5), (er * 0.3, er * 0.15, er * 0.3), u=6, v=4)
        E(t, "EyeShine", SHINE, (x + er * 0.3, y - er * 0.4, c[2] + dz - er * 0.45), (er * 0.14, er * 0.08, er * 0.14), u=5, v=3)
        if cheeks:
            cx = sx * cheeks * rx
            cdz = -0.22 * rz
            E(t, "Cheek", CHEEK, (cx, head_y(c, rad, cx, cdz) + 0.03, c[2] + cdz), (0.17 * rx, 0.05 * rx, 0.12 * rx), u=8, v=5)
    pts = []
    for i in range(5):
        u = (i - 2) / 2
        x = u * sw * rx
        dz = cz * rz + 0.12 * rz * u * u
        pts.append((x, head_y(c, rad, x, dz) + 0.015, c[2] + dz))
    tube(t, "Smile", MOUTH, pts, 0.028 * rx, seg=5, joints=False)
    if nose:
        key, hx, size, ndz = nose
        E(t, key, hx, (0, head_y(c, rad, 0, ndz * rz), c[2] + ndz * rz), (size, size * 0.8, size * 0.8), u=8, v=5)


def fat_path(t, label, hexs, pts, radii, steps=3, tip=None):
    out = []
    for i in range(len(pts) - 1):
        for s in range(steps):
            f = s / steps
            out.append((Vector(pts[i]).lerp(Vector(pts[i + 1]), f), radii[i] + (radii[i + 1] - radii[i]) * f))
    out.append((Vector(pts[-1]), radii[-1]))
    for k, (p, r) in enumerate(out):
        lab, hx = (tip[0], tip[1]) if tip and k >= len(out) - tip[2] else (label, hexs)
        E(t, lab, hx, (p.x, p.y, p.z), (r, r, r), u=8, v=4)


def bow(t, c, s, hexs, rot=(0, 0, 0)):
    for sx in (-1, 1):
        E(t, "Accent", hexs, (c[0] + sx * 0.2 * s, c[1], c[2]), (0.2 * s, 0.08 * s, 0.13 * s), rot=(0, 0, sx * -14), u=10, v=6, **SHINY)
    E(t, "Accent", hexs, c, (0.1 * s, 0.09 * s, 0.1 * s), u=8, v=5, **SHINY)


def pet_cat():
    t = new_pet("pet_cat")
    FUR, DARK, CRM, ACC = "F29A3C", "C96A1A", "FFE9CC", "E8453C"
    E(t, "Fur", FUR, (0, 0.12, 0.8), (0.78, 0.74, 0.8))
    E(t, "Belly", CRM, (0, -0.4, 0.72), (0.48, 0.3, 0.55))
    for sx in (-1, 1):
        E(t, "Fur", FUR, (sx * 0.6, 0.18, 0.42), (0.4, 0.5, 0.42))
        E(t, "Fur", FUR, (sx * 0.5, -0.2, 0.14), (0.28, 0.42, 0.14))
        E(t, "Fur", FUR, (sx * 0.3, -0.5, 0.3), (0.22, 0.24, 0.3))
        E(t, "Fur", FUR, (sx * 0.3, -0.6, 0.12), (0.26, 0.32, 0.12))
        for i in range(3):
            z = 0.8 + 0.12 + 0.2 * i
            f = math.sqrt(max(1 - ((z - 0.8) / 0.8) ** 2, 0.05))
            E(t, "FurDark", DARK, (sx * 0.78 * f, 0.1, z), (0.06, 0.3, 0.07), u=8, v=5)
    hc, hr = (0, -0.1, 1.72), (0.98, 0.88, 0.82)
    E(t, "Fur", FUR, hc, hr)
    for sx in (-1, 1):
        t.cyl("Fur", FUR, (sx * 0.58, -0.08, 2.38), 0.3, 0.55, seg=10, r2=0.03, rot=(0, sx * 20, 0), scale=(1, 0.6, 1))
        t.cyl("Inner", PINK, (sx * 0.56, -0.17, 2.34), 0.18, 0.42, seg=10, r2=0.02, rot=(0, sx * 20, 0), scale=(1, 0.4, 1))
    for x in (-0.2, 0.0, 0.2):
        E(t, "FurDark", DARK, (x, head_y(hc, hr, x, 0.5 * 0.82) + 0.02, hc[2] + 0.5 * 0.82), (0.045, 0.035, 0.17 if x == 0 else 0.13), u=8, v=5)
    for sx in (-1, 1):
        E(t, "Belly", CRM, (sx * 0.15, head_y(hc, hr, sx * 0.15, -0.2 * 0.82) + 0.0, hc[2] - 0.2 * 0.82), (0.19, 0.12, 0.14), u=8, v=5)
    face(t, hc, hr, ex=0.4, ez=0.08, es=0.17, nose=("Nose", "FF8FA3", 0.09, -0.12))
    for sx in (-1, 1):
        for k in (-1, 0, 1):
            y0 = head_y(hc, hr, sx * 0.5, -0.2 * 0.82)
            tube(t, "Whisker", WHITE, [(sx * 0.5, y0, hc[2] - 0.17), (sx * 1.1, y0 - 0.1, hc[2] - 0.15 + k * 0.14)], 0.016, seg=4, joints=False)
    pts = [(0.15, 0.8, 0.28), (0.45, 1.0, 0.35), (0.62, 1.05, 0.8), (0.55, 0.95, 1.3), (0.4, 0.82, 1.6)]
    tube(t, "Fur", FUR, pts, 0.16, seg=10)
    E(t, "FurDark", DARK, (0.4, 0.82, 1.62), (0.18, 0.18, 0.18), u=10, v=6)
    t.torus("Accent", ACC, (0, 0.02, 1.02), 0.8, 0.07, seg=22, rseg=5, **SHINY)
    t.sphere("Accent", ACC, (0, -0.76, 0.93), 0.13, u=10, v=6, **SHINY)
    return t


def pet_lamb():
    t = new_pet("pet_lamb")
    WOOL, FACE, LEG, ACC = "FFF8EC", "F4DCC6", "5B4A44", "4DABF7"
    bc, br = (0, 0.12, 0.8), (0.85, 0.8, 0.7)
    E(t, "Wool", WOOL, bc, br)
    for al, n, off, rr in ((-8, 8, 0, 0.34), (28, 8, 22, 0.34), (58, 5, 10, 0.32)):
        for i in range(n):
            ph = math.radians(off + i * 360.0 / n)
            a = math.radians(al)
            d = (math.cos(ph) * math.cos(a), math.sin(ph) * math.cos(a), math.sin(a))
            if d[1] < -0.3 and al > 20:
                continue
            E(t, "Wool", WOOL, (bc[0] + br[0] * d[0], bc[1] + br[1] * d[1], bc[2] + br[2] * d[2]), (rr, rr, rr), u=8, v=5)
    E(t, "Wool", WOOL, (0, 0.2, bc[2] + 0.7), (0.4, 0.4, 0.34), u=8, v=5)
    E(t, "Wool", WOOL, (0, 1.0, 0.8), (0.22, 0.22, 0.22), u=8, v=5)
    for sx in (-1, 1):
        for y in (-0.3, 0.55):
            t.cyl("Leg", LEG, (sx * 0.42, y, 0.3), 0.15, 0.55, seg=10)
            E(t, "Leg", LEG, (sx * 0.42, y - 0.04, 0.11), (0.19, 0.24, 0.11), u=10, v=6)
    hc, hr = (0, -0.62, 1.62), (0.66, 0.62, 0.66)
    E(t, "Face", FACE, hc, hr)
    for sx in (-1, 1):
        E(t, "Face", FACE, (sx * 0.84, -0.58, 1.68), (0.34, 0.13, 0.19), rot=(0, sx * 25, 0), u=10, v=6)
        E(t, "Inner", PINK, (sx * 0.88, -0.66, 1.67), (0.22, 0.05, 0.11), rot=(0, sx * 25, 0), u=8, v=5)
    for p in ((0, -0.5, 2.2, 0.3), (-0.24, -0.46, 2.1, 0.22), (0.24, -0.46, 2.1, 0.22), (0, -0.82, 2.08, 0.19)):
        E(t, "Wool", WOOL, (p[0], p[1], p[2]), (p[3], p[3], p[3]), u=8, v=5)
    face(t, hc, hr, ex=0.4, ez=0.05, es=0.19, cz=-0.32, nose=("Nose", "F29AA6", 0.07, -0.14))
    bow(t, (0, -0.93, 1.08), 1.3, ACC)
    return t


def pet_puppy():
    t = new_pet("pet_puppy")
    FUR, EAR, CRM, ACC = "D9A066", "A8693A", "FBE7C6", "3FA7FF"
    E(t, "Fur", FUR, (0, 0.15, 0.78), (0.75, 0.72, 0.78))
    E(t, "Belly", CRM, (0, -0.4, 0.7), (0.46, 0.3, 0.52))
    for sx in (-1, 1):
        E(t, "Fur", FUR, (sx * 0.58, 0.2, 0.4), (0.38, 0.5, 0.4))
        E(t, "Fur", FUR, (sx * 0.48, -0.18, 0.13), (0.27, 0.42, 0.13))
        E(t, "Fur", FUR, (sx * 0.3, -0.5, 0.3), (0.21, 0.24, 0.3))
        E(t, "Belly", CRM, (sx * 0.3, -0.6, 0.11), (0.25, 0.32, 0.11))
    hc, hr = (0, -0.15, 1.7), (0.95, 0.85, 0.8)
    E(t, "Fur", FUR, hc, hr)
    E(t, "Belly", CRM, (0, -0.86, 1.48), (0.46, 0.4, 0.34))
    for sx in (-1, 1):
        E(t, "Ear", EAR, (sx * 0.95, -0.02, 1.62), (0.2, 0.34, 0.66), rot=(0, -sx * 12, 0), u=10, v=7)
    E(t, "Patch", EAR, (0.4, head_y(hc, hr, 0.4, 0.1) + 0.04, 1.78), (0.3, 0.05, 0.3), u=10, v=6)
    face(t, hc, hr, ex=0.4, ez=0.08, es=0.15, cz=-0.4, sw=0.22, cheeks=0.7)
    E(t, "Nose", BLACK, (0, -1.24, 1.6), (0.14, 0.1, 0.1), u=10, v=6)
    E(t, "Tongue", "FF7D94", (0, -1.08, 1.2), (0.1, 0.05, 0.14), u=8, v=5)
    pts = [(0.0, 0.85, 0.35), (0.3, 1.1, 0.8), (0.5, 1.05, 1.2)]
    tube(t, "Fur", FUR, pts, 0.14, seg=10)
    E(t, "Belly", CRM, (0.5, 1.05, 1.22), (0.15, 0.15, 0.15), u=8, v=5)
    t.torus("Accent", ACC, (0, 0.0, 1.0), 0.78, 0.075, seg=22, rseg=5, **SHINY)
    t.cyl("Accent", ACC, (0, -0.8, 0.9), 0.14, 0.05, seg=14, rot=(90, 0, 0), **SHINY)
    return t


def pet_dove():
    t = new_pet("pet_dove")
    BODY, WING, ORANGE, ACC = "FAFAFF", "E3EAF6", "FF9F43", "FF8FB1"
    E(t, "Feather", BODY, (0, 0.12, 0.98), (0.85, 0.9, 0.88))
    E(t, "Feather", "FFFFFF", (0, -0.45, 0.85), (0.5, 0.35, 0.5))
    hc, hr = (0, -0.38, 1.75), (0.62, 0.58, 0.58)
    E(t, "Feather", BODY, hc, hr)
    face(t, hc, hr, ex=0.42, ez=0.08, es=0.15, cz=-0.42, sw=0.2, nose=None)
    t.cyl("Beak", ORANGE, (0, -1.06, 1.68), 0.12, 0.3, seg=10, r2=0.015, rot=(90, 0, 0), scale=(1, 0.8, 1))
    for sx in (-1, 1):
        E(t, "Wing", WING, (sx * 0.8, 0.2, 1.05), (0.16, 0.58, 0.64), rot=(0, sx * 10, 0), u=12, v=8)
        for k in range(3):
            E(t, "Wing", WING, (sx * (0.82 - k * 0.02), 0.5 + k * 0.17, 0.62 - k * 0.04), (0.12, 0.16, 0.34), rot=(0, sx * 8, sx * -10 * (k - 1)), u=8, v=5)
        t.cyl("Leg", ORANGE, (sx * 0.28, -0.02, 0.08), 0.06, 0.16, seg=8)
        for k in (-1, 0, 1):
            E(t, "Leg", ORANGE, (sx * 0.28 + k * 0.09, -0.14 - (0.04 if k == 0 else 0), 0.04), (0.04, 0.17, 0.035), rot=(0, 0, k * -22), u=6, v=4)
    for k in (-1, 0, 1):
        E(t, "Wing", WING, (k * 0.22, 1.08, 0.55 + 0.04 * (1 - abs(k))), (0.16, 0.5, 0.09), rot=(-12, 0, k * 22), u=8, v=5)
    bow(t, (0, -0.72, 1.28), 1.2, ACC)
    return t


def pet_fox():
    t = new_pet("pet_fox")
    FUR, DARK, CRM, SOCK, ACC = "EE8A2B", "4A2E22", "FFF3E3", "4A2E22", "2EC4B6"
    E(t, "Fur", FUR, (0, 0.1, 0.78), (0.7, 0.7, 0.78))
    E(t, "Belly", CRM, (0, -0.38, 0.7), (0.45, 0.3, 0.55))
    for sx in (-1, 1):
        E(t, "Fur", FUR, (sx * 0.55, 0.15, 0.4), (0.33, 0.46, 0.4))
        E(t, "Sock", SOCK, (sx * 0.45, -0.2, 0.1), (0.24, 0.36, 0.1))
        E(t, "Sock", SOCK, (sx * 0.3, -0.5, 0.3), (0.17, 0.2, 0.3))
        E(t, "Sock", SOCK, (sx * 0.3, -0.58, 0.1), (0.21, 0.28, 0.1))
    hc, hr = (0, -0.15, 1.7), (0.9, 0.8, 0.74)
    E(t, "Fur", FUR, hc, hr)
    E(t, "Belly", CRM, (0, -0.82, 1.5), (0.38, 0.36, 0.3))
    for sx in (-1, 1):
        E(t, "Belly", CRM, (sx * 0.72, -0.34, 1.36), (0.22, 0.26, 0.2))
        R = Matrix.Rotation(math.radians(sx * 14), 3, 'Y')
        c = Vector((sx * 0.55, -0.02, 2.3))
        t.cyl("Fur", FUR, (c.x, c.y, c.z), 0.3, 0.7, seg=10, r2=0.03, rot=(0, sx * 14, 0), scale=(1, 0.6, 1))
        tp = c + R @ Vector((0, 0, 0.217))
        t.cyl("FurDark", DARK, (tp.x, tp.y, tp.z), 0.148, 0.266, seg=10, r2=0.04, rot=(0, sx * 14, 0), scale=(1, 0.6, 1))
        ip = c + R @ Vector((0, -0.09, -0.04))
        t.cyl("Inner", "FFD9B8", (ip.x, ip.y, ip.z), 0.17, 0.5, seg=10, r2=0.02, rot=(0, sx * 14, 0), scale=(1, 0.4, 1))
    face(t, hc, hr, ex=0.4, ez=0.08, es=0.16, cz=-0.4, sw=0.2, cheeks=0.66)
    E(t, "Nose", BLACK, (0, -1.14, 1.58), (0.1, 0.08, 0.08), u=8, v=5)
    pts = [(0.3, 0.75, 0.3), (0.72, 0.95, 0.4), (1.0, 0.92, 0.82), (1.06, 0.78, 1.28), (0.94, 0.62, 1.62), (0.84, 0.5, 1.88)]
    fat_path(t, "Fur", FUR, pts, [0.2, 0.28, 0.34, 0.36, 0.32, 0.28], steps=2, tip=("TailTip", WHITE, 3))
    t.torus("Accent", ACC, (0, 0.02, 1.02), 0.8, 0.1, seg=22, rseg=5, **SHINY)
    t.box("Accent", ACC, (0.4, -0.72, 0.8), (0.26, 0.09, 0.5), bevel=0.04, rot=(0, 0, -12), **SHINY)
    return t


def pet_hedgehog():
    t = new_pet("pet_hedgehog")
    BACK, FACE = "6B4423", "F3D3A8"
    bc, br = (0, 0.25, 0.92), (0.95, 1.0, 0.85)
    E(t, "Back", BACK, bc, br)
    E(t, "Face", FACE, (0, -0.4, 0.68), (0.62, 0.5, 0.56))
    hc, hr = (0, -0.78, 0.85), (0.62, 0.6, 0.58)
    E(t, "Face", FACE, hc, hr)
    E(t, "Face", FACE, (0, -1.22, 0.7), (0.3, 0.38, 0.26))
    E(t, "Nose", BLACK, (0, -1.58, 0.72), (0.11, 0.09, 0.09), u=8, v=5)
    for sx in (-1, 1):
        E(t, "Face", FACE, (sx * 0.46, -0.56, 1.3), (0.18, 0.12, 0.2), u=8, v=5)
        E(t, "Inner", PINK, (sx * 0.46, -0.62, 1.3), (0.11, 0.06, 0.12), u=6, v=4)
        E(t, "Face", FACE, (sx * 0.4, -0.62, 0.14), (0.2, 0.28, 0.14), u=8, v=5)
        E(t, "Face", FACE, (sx * 0.5, 0.5, 0.14), (0.22, 0.3, 0.14), u=8, v=5)
    face(t, hc, hr, ex=0.45, ez=0.22, es=0.2, cz=-0.38, sw=0.2, cheeks=0.7)
    rnd = random.Random(4)
    ga = math.pi * (3 - math.sqrt(5))
    n = 190
    for i in range(n):
        z = 1 - 2 * (i + 0.5) / n
        rr = math.sqrt(max(1 - z * z, 0))
        d = Vector((math.cos(ga * i) * rr, math.sin(ga * i) * rr, z))
        if d.y < -0.3 or d.z < -0.25:
            continue
        p = Vector((bc[0] + br[0] * d.x, bc[1] + br[1] * d.y, bc[2] + br[2] * d.z))
        nrm = Vector((d.x / br[0], d.y / br[1], d.z / br[2])).normalized()
        L = 0.5 + 0.12 * rnd.random()
        M = align_z(p - nrm * 0.06, nrm, spin=rnd.uniform(0, 70))
        key, hx = ("Spike", "7A4B28") if i % 2 == 0 else ("Spike2", "9C6B3C")
        t.lathe(key, hx, tuple(M.to_translation()), [(0.0, 0.0), (0.17, 0.0), (0.0, L)], seg=5, rot=edeg(M), smooth=False)
    bow(t, (0, -0.62, 1.42), 1.0, "E8453C")
    return t


def pet_lion_cub():
    t = new_pet("pet_lion_cub")
    FUR, MANE, CRM, ACC = "F4B73F", "B8651F", "FFE9B8", "FFC93C"
    E(t, "Fur", FUR, (0, 0.15, 0.78), (0.72, 0.7, 0.78))
    E(t, "Belly", CRM, (0, -0.38, 0.7), (0.45, 0.3, 0.52))
    for sx in (-1, 1):
        E(t, "Fur", FUR, (sx * 0.58, 0.2, 0.4), (0.38, 0.5, 0.4))
        E(t, "Fur", FUR, (sx * 0.48, -0.18, 0.13), (0.27, 0.42, 0.13))
        E(t, "Fur", FUR, (sx * 0.3, -0.5, 0.3), (0.22, 0.25, 0.3))
        E(t, "Belly", CRM, (sx * 0.3, -0.6, 0.11), (0.26, 0.32, 0.11))
    hc, hr = (0, -0.15, 1.6), (0.82, 0.76, 0.76)
    E(t, "Mane", MANE, (0, 0.42, 1.58), (0.8, 0.45, 0.8), u=10, v=6)
    for i in range(12):
        a = math.radians(i * 360.0 / 12 + 8)
        E(t, "Mane", MANE, (0.95 * math.cos(a), 0.1, 1.6 + 0.82 * math.sin(a)), (0.34, 0.3, 0.34), u=8, v=5)
    for i in range(6):
        a = math.radians(i * 60.0 + 22)
        E(t, "Mane", "D38A33", (0.62 * math.cos(a), -0.02, 1.6 + 0.58 * math.sin(a)), (0.32, 0.26, 0.32), u=8, v=5)
    E(t, "Fur", FUR, hc, hr)
    E(t, "Belly", CRM, (0, -0.8, 1.42), (0.4, 0.36, 0.3))
    for sx in (-1, 1):
        E(t, "Fur", FUR, (sx * 0.56, -0.32, 2.12), (0.2, 0.14, 0.2), u=8, v=5)
        E(t, "Inner", PINK, (sx * 0.56, -0.43, 2.12), (0.12, 0.06, 0.12), u=6, v=4)
    face(t, hc, hr, ex=0.4, ez=0.08, es=0.16, cz=-0.4, sw=0.2, cheeks=0.68)
    E(t, "Nose", "8A4B3B", (0, -1.1, 1.52), (0.11, 0.08, 0.08), u=8, v=5)
    pts = [(0.1, 0.85, 0.3), (0.42, 1.15, 0.35), (0.7, 1.2, 0.7), (0.78, 1.0, 1.1)]
    tube(t, "Fur", FUR, pts, 0.1, seg=8)
    E(t, "Mane", MANE, (0.8, 0.95, 1.3), (0.22, 0.22, 0.28), u=8, v=5)
    E(t, "Mane", MANE, (0.9, 0.95, 1.12), (0.17, 0.17, 0.2), u=8, v=5)
    E(t, "Mane", MANE, (0.7, 0.92, 1.15), (0.17, 0.17, 0.2), u=8, v=5)
    cx, cy, cz = 0.0, -0.32, 2.3
    t.cyl("Accent", ACC, (cx, cy, cz + 0.06), 0.28, 0.14, seg=14, **SHINY)
    for k in range(5):
        a = 2 * math.pi * k / 5 + math.pi / 2
        t.cyl("Accent", ACC, (cx + math.cos(a) * 0.22, cy + math.sin(a) * 0.22, cz + 0.25), 0.075, 0.22, seg=6, r2=0.0, **SHINY)
    return t


def pet_peacock():
    t = new_pet("pet_peacock")
    BODY, NECK, LEGC, ACC = "1FA9A0", "1E86D1", "C79B6B", "F2B632"
    E(t, "Body", BODY, (0, 0.15, 0.95), (0.58, 0.78, 0.62))
    E(t, "Neck", NECK, (0, -0.38, 1.12), (0.42, 0.38, 0.5))
    for sx in (-1, 1):
        E(t, "Wing", "178F8A", (sx * 0.48, 0.22, 1.0), (0.14, 0.52, 0.4), u=10, v=6)
        t.cyl("Leg", LEGC, (sx * 0.2, -0.02, 0.21), 0.06, 0.42, seg=8)
        for k in (-1, 0, 1):
            E(t, "Leg", LEGC, (sx * 0.2 + k * 0.09, -0.15 - (0.04 if k == 0 else 0), 0.035), (0.035, 0.17, 0.03), rot=(0, 0, k * -22), u=6, v=4)
    tube(t, "Neck", NECK, [(0, -0.4, 1.3), (0, -0.52, 1.6), (0, -0.6, 1.84)], 0.2, seg=10, joints=False)
    hc, hr = (0, -0.62, 2.0), (0.4, 0.38, 0.38)
    E(t, "Neck", NECK, hc, hr)
    face(t, hc, hr, ex=0.46, ez=0.1, es=0.17, cz=-0.5, sw=0.2, cheeks=0.7)
    t.cyl("Beak", "F5B642", (0, -1.04, 1.92), 0.09, 0.22, seg=8, r2=0.012, rot=(90, 0, 0))
    for k in (-1, 0, 1):
        tube(t, "Crest", "14204A", [(k * 0.04, -0.6, 2.32), (k * 0.18, -0.58, 2.66)], 0.016, seg=5, joints=False)
        t.sphere("Accent", ACC, (k * 0.18, -0.58, 2.7), 0.07, u=8, v=5, **SHINY)
    pv = (0, 0.6, 0.95)
    for i in range(13):
        ang = -80 + i * 160.0 / 12
        a = math.radians(ang)
        d = Vector((math.sin(a), 0, math.cos(a)))
        c = Vector(pv) + d * (0.3 + 0.72)
        E(t, "Feather", "2E9E5B", (c.x, c.y, c.z), (0.2, 0.05, 0.72), rot=(0, ang, 0), u=8, v=4)
        for key, hx, rr, dz, off, sg in (("EyeGold", "F2C14E", 0.15, 0.2, 0.0, 8), ("EyeBlue", "1F6FD0", 0.1, 0.14, -0.035, 6), ("EyeDark", "14204A", 0.05, 0.08, -0.07, 6)):
            ce = Vector(pv) + d * 1.38 + Vector((0, off - 0.05, 0))
            t.cyl(key, hx, (ce.x, ce.y, ce.z), rr, 0.035, seg=sg, rot=(90, ang, 0), scale=(1, dz / rr, 1))
    for i in range(12):
        ang = -73 + i * 146.0 / 11
        a = math.radians(ang)
        d = Vector((math.sin(a), 0, math.cos(a)))
        c = Vector(pv) + d * (0.3 + 0.62) + Vector((0, 0.14, 0))
        E(t, "Feather2", "1F7A6B", (c.x, c.y, c.z), (0.2, 0.05, 0.62), rot=(0, ang, 0), u=8, v=4)
    return t


PETS = {
    "cat": pet_cat, "lamb": pet_lamb, "puppy": pet_puppy, "dove": pet_dove,
    "fox": pet_fox, "hedgehog": pet_hedgehog, "lion_cub": pet_lion_cub, "peacock": pet_peacock,
}


def build_pets(names=None, do_export=True):
    out = {}
    for name in (names or list(PETS)):
        reset()
        toy = PETS[name]()
        objs = toy.finish()
        mn, mx = bounds(objs)
        entry = {"tris": tris(objs), "min": [round(v, 2) for v in mn], "max": [round(v, 2) for v in mx]}
        entry["labels"] = sorted({o.name.split("__")[0] for o in objs})
        if do_export:
            entry.update(export("pet_" + name, objs))
        render_icon(objs, "pet_" + name, size=384, direction=(0.55, -1.0, 0.32), pad=1.12)
        out[name] = entry
    return out
