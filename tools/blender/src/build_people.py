K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "kit2.py").read())

EYE, SHINE, MOUTH, CHEEK = "23233A", "FFFFFF", "8A3B3B", "FF9AA2"
WHITE, BLUE = "FFFFFF", "2F6FE0"

_orig_sphere = Toy.sphere


def _sphere(self, label, hexs, c, r, u=None, v=None, **kw):
    if u is None:
        u, v = (8, 5) if r < 0.2 else ((12, 8) if r < 0.5 else (20, 12))
    _orig_sphere(self, label, hexs, c, r, u=u, v=v, **kw)


Toy.sphere = _sphere


def dome(t, label, hexs, c, r, h, seg=20, rot=(0, 0, 0), scale=(1, 1, 1), steps=5, **kw):
    prof = []
    for i in range(steps + 1):
        a = (math.pi / 2) * i / steps
        prof.append((r * math.cos(a), h * math.sin(a)))
    t.lathe(label, hexs, c, prof, seg=seg, rot=rot, scale=scale, **kw)


def tube(t, label, hexs, pts, r, seg=8, **kw):
    for a, b in zip(pts, pts[1:]):
        va, vb = Vector(a), Vector(b)
        d = vb - va
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        e = q.to_euler('XYZ')
        mid = (va + vb) / 2
        t.cyl(label, hexs, (mid.x, mid.y, mid.z), r, d.length, seg=seg,
              rot=(math.degrees(e.x), math.degrees(e.y), math.degrees(e.z)), **kw)
    for p in pts:
        t.sphere(label, hexs, p, r, u=5, v=3, **kw)


def surface_y(hr, x, dz):
    return -math.sqrt(max(hr * hr - x * x - dz * dz, 0.01))


def person(name, H, skin, hairc, top, bot, shoe, sex="m", hair="short", beard=None, kip=None, knit=False,
           tal=False, child=False):
    t = Toy(name, rough=0.5)
    s = H / 5.5
    hr = 0.92 * (1.14 if child else 1.0) * (s if not child else s)
    hcz = H - hr - 0.1 * s
    hip = 2.45 * s
    w = 1.0 if sex == "m" else 0.9
    arm_r = (0.33 if sex == "m" else 0.29) * s

    for sx in (-1, 1):
        if sex == "m":
            t.cyl("Cloth_Bottom", bot, (sx * 0.5 * s, 0, (0.3 * s + hip) / 2), 0.42 * s, hip - 0.3 * s, seg=10)
        else:
            t.cyl("Legs", skin, (sx * 0.4 * s, 0, 0.55 * s), 0.27 * s, 0.6 * s, seg=12)
        t.box("Shoes", shoe, (sx * 0.5 * s, -0.22 * s, 0.26 * s), (0.9 * s, 1.5 * s, 0.52 * s), bevel=0.12 * s)
    if sex == "f":
        t.cyl("Cloth_Bottom", bot, (0, 0, (0.62 * s + hip + 0.15 * s) / 2), 1.08 * s, hip + 0.15 * s - 0.62 * s, seg=20, r2=0.7 * s)

    t.box("Cloth_Top", top, (0, 0, 3.15 * s), (1.78 * w * s, 1.1 * s, 1.5 * s), bevel=0.4 * s)
    t.cyl("Head", skin, (0, 0, 3.98 * s), 0.3 * s, 0.4 * s, seg=12)
    for sx in (-1, 1):
        t.cyl("Cloth_Top", top, (sx * 1.13 * w * s, 0, 3.0 * s), arm_r, 1.35 * s, seg=10, rot=(0, -sx * 7, 0), bevel=0.0)
        t.sphere("Cloth_Top", top, (sx * 1.06 * w * s, 0, 3.66 * s), arm_r * 1.15, u=8, v=5)
        t.sphere("Hands", skin, (sx * 1.22 * w * s, 0, 2.28 * s), 0.34 * s, u=8, v=6)

    t.sphere("Head", skin, (0, 0, hcz), hr, u=20, v=14)

    ex = 0.36 * hr
    edz = 0.06 * hr
    for sx in (-1, 1):
        y = surface_y(hr, sx * ex, edz) + 0.03
        t.sphere("Eye", EYE, (sx * ex, y, hcz + edz), 0.14 * hr, scale=(0.78, 0.55, 1.25), u=8, v=6)
        t.sphere("EyeShine", SHINE, (sx * ex - 0.035 * hr, y - 0.045 * hr, hcz + edz + 0.07 * hr), 0.045 * hr, u=6, v=4)
        cy = surface_y(hr, sx * 0.6 * hr, -0.2 * hr) + 0.03
        t.sphere("Cheek", CHEEK, (sx * 0.6 * hr, cy, hcz - 0.2 * hr), 0.17 * hr, scale=(1, 0.3, 0.72), u=8, v=5)
    ny = surface_y(hr, 0, -0.1 * hr) + 0.015
    t.sphere("Nose", skin, (0, ny, hcz - 0.1 * hr), 0.085 * hr, scale=(1, 0.8, 0.9))
    smile = []
    for i in range(7):
        u = (i - 3) / 3
        x = u * 0.26 * hr
        dz = -0.38 * hr + 0.13 * hr * u * u
        smile.append((x, surface_y(hr, x, dz) + 0.02, hcz + dz))
    tube(t, "Smile", MOUTH, smile, 0.034 * hr, seg=5)
    for sx in (-1, 1):
        t.sphere("Head", skin, (sx * hr * 0.97, hr * 0.06, hcz - 0.04 * hr), 0.2 * hr, scale=(0.45, 0.8, 1.15))

    cap_r = hr * 1.07
    dome(t, "Hair", hairc, (0, 0.03 * hr, hcz), cap_r, cap_r * 1.02, seg=18, rot=(-26, 0, 0), steps=5)
    if hair == "long":
        t.sphere("Hair", hairc, (0, hr * 0.6, hcz - hr * 0.5), hr * 0.98, scale=(1.04, 0.62, 1.45), u=16, v=10)
    elif hair == "bun":
        t.sphere("Hair", hairc, (0, hr * 0.78, hcz + hr * 0.8), hr * 0.4)
    elif hair == "ponytail":
        t.sphere("Hair", hairc, (0, hr * 0.92, hcz + hr * 0.5), hr * 0.3)
        t.cyl("Hair", hairc, (0, hr * 1.05, hcz - hr * 0.18), hr * 0.07, hr * 1.25, seg=10, r2=hr * 0.24, rot=(-10, 0, 0))
    if beard:
        t.sphere("Beard", beard, (0, -hr * 0.2, hcz - hr * 0.82), hr * 0.62, scale=(1.0, 0.8, 0.58))
        for sx in (-1, 1):
            t.sphere("Beard", beard, (sx * hr * 0.66, -hr * 0.3, hcz - hr * 0.42), hr * 0.3, scale=(0.7, 0.9, 1.2))
    if kip:
        kr = hr * (0.62 if knit else 0.5)
        dome(t, "Kippah", kip, (0, hr * 0.3, hcz + hr * 0.86), kr, kr * 0.5, seg=16, rot=(-22, 0, 0), steps=4)
    if tal:
        for sx in (-1, 1):
            t.box("Tallit", WHITE, (sx * 0.7 * s, 0.0, 3.86 * s), (1.0 * s, 1.3 * s, 0.3 * s), bevel=0.12 * s)
            t.box("Tallit", WHITE, (sx * 0.58 * s, -0.6 * s, 3.0 * s), (0.5 * s, 0.14 * s, 1.75 * s), bevel=0.05 * s)
            t.box("TallitStripe", BLUE, (sx * 0.58 * s, -0.66 * s, 2.35 * s), (0.6 * s, 0.05 * s, 0.13 * s), bevel=0.02 * s)
            t.box("TallitStripe", BLUE, (sx * 0.58 * s, -0.66 * s, 2.15 * s), (0.6 * s, 0.05 * s, 0.13 * s), bevel=0.02 * s)
            for fx in (-0.18, 0, 0.18):
                t.cyl("Tallit", WHITE, (sx * 0.58 * s + fx * s, -0.66 * s, 1.95 * s), 0.025 * s, 0.4 * s, seg=6)
        t.box("Tallit", WHITE, (0, 0.6 * s, 3.0 * s), (1.7 * s, 0.14 * s, 1.75 * s), bevel=0.05 * s)
        t.box("TallitStripe", BLUE, (0, 0.66 * s, 2.35 * s), (1.7 * s, 0.05 * s, 0.13 * s), bevel=0.02 * s)
    return t


SPECS = {
    "congregant_1": dict(H=5.5, skin="EAC09A", hairc="3B2A1E", top="1F2A44", bot="2A2A2A", shoe="1A1A1A", sex="m", hair="short", kip="1C1C1C", tal=True),
    "congregant_2": dict(H=5.3, skin="C68642", hairc="1E1410", top="D9503F", bot="2F3E66", shoe="5A3A22", sex="f", hair="long"),
    "congregant_3": dict(H=5.6, skin="8D5524", hairc="141414", top="4CA36B", bot="C8B48A", shoe="6B4A2E", sex="m", hair="short", kip="4A7BD0", knit=True),
    "congregant_4": dict(H=5.4, skin="F1C27D", hairc="A0522D", top="7A5CC4", bot="5A6B7D", shoe="2B2B2B", sex="f", hair="bun"),
    "congregant_5": dict(H=5.45, skin="FFDBAC", hairc="BEBEBE", top="6E4B3A", bot="3A3A3A", shoe="1F1F1F", sex="m", hair="short", beard="CFCFCF", kip="2F3E66"),
    "congregant_6": dict(H=4.3, skin="6B4423", hairc="140D09", top="FF8FB1", bot="3E7CC9", shoe="F5F5F5", sex="f", hair="ponytail", child=True),
}


def build_people(names=None, do_export=False, preview=True):
    out = {}
    all_objs = []
    for index, name in enumerate(names or list(SPECS)):
        if not preview:
            reset()
        elif index == 0:
            reset()
        toy = person(name, **SPECS[name])
        objs = toy.finish()
        if preview:
            for o in objs:
                o.location.x += index * 3.6
                bpy.context.view_layer.update()
            all_objs.extend(objs)
            out[name] = {"parts": len(objs), "tris": tris(objs)}
        else:
            entry = {"parts": len(objs), "tris": tris(objs)}
            if do_export:
                entry.update(export(name, objs))
            out[name] = entry
    if preview:
        render_icon(all_objs, "people_lineup", size=1400, direction=(0.0, -1.0, 0.25), pad=1.08)
    return out
