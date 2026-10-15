K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "kit2.py").read())

_orig_sphere = Toy.sphere


def _sphere(self, label, hexs, c, r, u=None, v=None, **kw):
    if u is None:
        u, v = (8, 5) if r < 0.2 else ((12, 8) if r < 0.5 else ((16, 10) if r < 2.0 else (22, 14)))
    _orig_sphere(self, label, hexs, c, r, u=u, v=v, **kw)


Toy.sphere = _sphere


def tube(t, label, hexs, pts, r, seg=8, joints=True, r2=None, **kw):
    for a, b in zip(pts, pts[1:]):
        va, vb = Vector(a), Vector(b)
        d = vb - va
        if d.length < 1e-5:
            continue
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        e = q.to_euler('XYZ')
        mid = (va + vb) / 2
        t.cyl(label, hexs, (mid.x, mid.y, mid.z), r, d.length, seg=seg,
              rot=(math.degrees(e.x), math.degrees(e.y), math.degrees(e.z)), **kw)
    if joints:
        for p in pts[1:-1]:
            t.sphere(label, hexs, p, r, u=8, v=5, **kw)


def dome(t, label, hexs, c, r, h, seg=20, rot=(0, 0, 0), scale=(1, 1, 1), steps=5, **kw):
    prof = []
    for i in range(steps + 1):
        a = (math.pi / 2) * i / steps
        prof.append((r * math.cos(a), h * math.sin(a)))
    t.lathe(label, hexs, c, prof, seg=seg, rot=rot, scale=scale, **kw)


def star6(t, label, hexs, c, r, thick, plane="XZ"):
    for flip in (1, -1):
        pts = [(0, r * flip), (-r * 0.866, -r * 0.5 * flip), (r * 0.866, -r * 0.5 * flip)]
        pts = [(c[0] + x, c[2] + z) for x, z in pts]
        t.poly(label, hexs, pts, c[1] - thick / 2, c[1] + thick / 2, bevel=min(0.03, thick * 0.3), plane=plane)


def ring_pts(cx, cy, z, r, n, phase=0.0):
    return [(cx + math.cos(phase + 2 * math.pi * i / n) * r, cy + math.sin(phase + 2 * math.pi * i / n) * r, z) for i in range(n)]


def bowl(t, label, hexs, c, r_out, r_in, depth, thick, seg=28, **kw):
    prof = [(0, 0), (r_out * 0.35, 0), (r_out * 0.78, depth * 0.28), (r_out, depth * 0.9), (r_out, depth),
            (r_in, depth), (r_in, depth - thick), (r_in * 0.78, depth * 0.3 + thick), (0, thick)]
    t.lathe(label, hexs, c, prof, seg=seg, **kw)


def build_set(builders, names=None, do_export=False, preview_prefix="prop_", size=384, directions=None):
    out = {}
    for name in (names or list(builders)):
        reset()
        toy = builders[name]()
        objs = toy.finish()
        d = (directions or {}).get(name, (0.5, -1.0, 0.45))
        render_icon(objs, preview_prefix + name, size=size, direction=d, pad=1.08)
        entry = {"parts": len(objs), "tris": tris(objs)}
        if do_export:
            entry.update(export(preview_prefix + name, objs))
        out[name] = entry
    return out
