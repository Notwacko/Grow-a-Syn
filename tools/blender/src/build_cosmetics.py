K = "/Users/wacko/Documents/growasyn/art/src/"
exec(open(K + "toylib.py").read())
import random

BLACK, CHAR, GRAY, NAVY, WHITE = "1C1C24", "30323E", "7C8294", "26396E", "F6F6FA"
GOLD, GOLD_D, GOLD_L = "F2B632", "C98A10", "FFE08A"
SILVER = "D5DAE6"
CREAM = "FFF1D0"
BLUE = "3B72E0"
SKY = "3FA7FF"
FLAME = "FFB347"
LEATHER, LEATHER_L, LEATHER_D = "9A5A2E", "B8723C", "5E341A"
STRAW, STRAW_D = "EFCB78", "D2A24C"


def new(name, rough=0.55):
    t = Toy(name, rough=rough)
    t.marker("Origin", (0, 0, 0), (0.04, 0.04, 0.04))
    return t


def edeg(M):
    e = M.to_euler('XYZ')
    return (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z))


def align_z(pos, normal, spin=0.0):
    q = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized())
    M = q.to_matrix().to_4x4()
    if spin:
        M = M @ Matrix.Rotation(math.radians(spin), 4, 'Z')
    return Matrix.Translation(Vector(pos)) @ M


def prism(t, label, hexs, pts, thick, M, bevel=0.0, **kw):
    bm = t.bm(label, hexs, **kw)
    a = [bm.verts.new(M @ Vector((x, y, -thick / 2))) for x, y in pts]
    b = [bm.verts.new(M @ Vector((x, y, thick / 2))) for x, y in pts]
    n = len(pts)
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    if bevel > 0:
        t._bevel(bm, a + b, bevel)


def mstar(t, label, hexs, M, r, thick, bevel=0.0, **kw):
    for flip in (1, -1):
        pts = [(0, r * flip), (-r * 0.866, -r * 0.5 * flip), (r * 0.866, -r * 0.5 * flip)]
        prism(t, label, hexs, pts, thick, M, bevel, **kw)


def ring_band(t, label, hexs, c, rin, rout, h, seg=28, ch=0.02, rot=(0, 0, 0), scale=(1, 1, 1), **kw):
    prof = [(rin, 0), (rout - ch, 0), (rout, ch), (rout, h - ch), (rout - ch, h), (rin, h), (rin, 0)]
    t.lathe(label, hexs, c, prof, seg=seg, rot=rot, scale=scale, **kw)


def scatter(seed, n, xs, zs, gap, tries=600):
    rnd = random.Random(seed)
    pts = []
    k = 0
    while len(pts) < n and k < tries:
        k += 1
        x = rnd.uniform(xs[0], xs[1])
        z = rnd.uniform(zs[0], zs[1])
        if all((x - px) ** 2 + (z - pz) ** 2 > gap * gap for px, pz in pts):
            pts.append((x, z))
    return pts


def grid_shell(t, label, hexs, fn, nu, nv, th, off=0.0, u0=-1.0, u1=1.0, v0=0.0, v1=1.0, **kw):
    bm = t.bm(label, hexs, **kw)
    P = []
    for i in range(nv + 1):
        v = v0 + (v1 - v0) * i / nv
        P.append([Vector(fn(u0 + (u1 - u0) * j / nu, v)) + Vector((0, off, 0)) for j in range(nu + 1)])
    D = Vector((0, th, 0))
    vo = [[bm.verts.new(p) for p in row] for row in P]
    vi = [[bm.verts.new(p - D) for p in row] for row in P]
    for i in range(nv):
        for j in range(nu):
            f = bm.faces.new((vo[i][j], vo[i][j + 1], vo[i + 1][j + 1], vo[i + 1][j]))
            f.smooth = True
            g = bm.faces.new((vi[i][j], vi[i + 1][j], vi[i + 1][j + 1], vi[i][j + 1]))
            g.smooth = True
    for i in range(nv):
        bm.faces.new((vo[i][0], vo[i + 1][0], vi[i + 1][0], vi[i][0]))
        bm.faces.new((vo[i][nu], vi[i][nu], vi[i + 1][nu], vo[i + 1][nu]))
    for j in range(nu):
        bm.faces.new((vo[0][j], vi[0][j], vi[0][j + 1], vo[0][j + 1]))
        bm.faces.new((vo[nv][j], vo[nv][j + 1], vi[nv][j + 1], vi[nv][j]))


def tallit(name, cloth, stripes, shoulder, atarah, rough=0.5, fringe=WHITE, pattern=None):
    t = new(name, rough)
    for sx in (-1, 1):
        t.box("UpperTorso.Cloth", cloth, (sx * 0.72, 0.0, 1.02), (1.1, 1.3, 0.22), bevel=0.09, rot=(0, sx * 8, 0))
        t.box("UpperTorso.Cloth", cloth, (sx * 0.64, -0.62, 0.05), (0.62, 0.12, 2.0), bevel=0.05)
        for key, hx, z, h in stripes:
            t.box("UpperTorso." + key, hx, (sx * 0.64, -0.685, z), (0.64, 0.05, h), bevel=0.0)
        R = Matrix.Rotation(math.radians(sx * 8), 3, 'Y')
        for k, (key, hx) in enumerate(shoulder):
            c = Vector((sx * 0.72, 0.0, 1.02)) + R @ Vector((sx * (0.2 + 0.13 * k), 0.0, 0.118))
            t.box("UpperTorso." + key, hx, (c.x, c.y, c.z), (0.1, 1.2, 0.04), bevel=0.0, rot=(0, sx * 8, 0))
        for k in range(4):
            x = sx * (0.4 + 0.14 * k)
            tube(t, "UpperTorso.Fringe", fringe, [(x, -0.62, -0.98), (x, -0.62, -1.42)], 0.026, seg=5, joints=False)
            t.sphere("UpperTorso.Fringe", fringe, (x, -0.62, -0.97), 0.05, u=6, v=4)
    t.box("UpperTorso.Cloth", cloth, (0, 0.62, 0.05), (1.8, 0.12, 2.0), bevel=0.05)
    for key, hx, z, h in stripes:
        t.box("UpperTorso." + key, hx, (0, 0.685, z), (1.8, 0.05, h), bevel=0.0)
    for k in range(8):
        x = -0.77 + k * 0.22
        tube(t, "UpperTorso.Fringe", fringe, [(x, 0.62, -0.98), (x, 0.62, -1.42)], 0.026, seg=5, joints=False)
        t.sphere("UpperTorso.Fringe", fringe, (x, 0.62, -0.97), 0.05, u=6, v=4)
    ring_band(t, "UpperTorso.Atarah", atarah, (0, -0.02, 1.0), 0.33, 0.4, 0.14, seg=20, metal=0.5, rough=0.3)
    if pattern:
        pattern(t)
    return t


def pat_stone(t):
    rows = [0.75, 0.47, 0.19, -0.09, -0.37]
    tones = ("D9BF8C", "C9AC76")
    n = 0
    for ri, z in enumerate(rows):
        if ri % 2 == 0:
            fronts = [(0.64, 0.5)]
            backs = [(-0.6, 0.55), (0.0, 0.55), (0.6, 0.55)]
        else:
            fronts = [(0.49, 0.27), (0.79, 0.27)]
            backs = [(-0.76, 0.26), (-0.3, 0.55), (0.3, 0.55), (0.76, 0.26)]
        for sx in (-1, 1):
            for x, w in fronts:
                key, hx = ("Stone", tones[0]) if n % 2 == 0 else ("Stone2", tones[1])
                t.box("UpperTorso." + key, hx, (sx * x, -0.695, z), (w, 0.03, 0.24), bevel=0.0)
                n += 1
        for x, w in backs:
            key, hx = ("Stone", tones[0]) if n % 2 == 0 else ("Stone2", tones[1])
            t.box("UpperTorso." + key, hx, (x, 0.695, z), (w, 0.03, 0.24), bevel=0.0)
            n += 1


def pat_stars(t):
    rnd = random.Random(5)
    for sx in (-1, 1):
        for x, z in scatter(11 + sx, 7, (0.42, 0.86), (-0.3, 0.85), 0.27):
            M = align_z((sx * x, -0.7, z), (0, -1, 0), spin=rnd.uniform(0, 60))
            mstar(t, "UpperTorso.Star", WHITE, M, rnd.uniform(0.06, 0.09), 0.025)
    for x, z in scatter(3, 22, (-0.8, 0.8), (-0.3, 0.88), 0.27):
        M = align_z((x, 0.7, z), (0, 1, 0), spin=rnd.uniform(0, 60))
        mstar(t, "UpperTorso.Star", WHITE, M, rnd.uniform(0.06, 0.1), 0.025)


def tallit_royal():
    st = [("Stripe", WHITE, -0.55, 0.12), ("Stripe", WHITE, -0.78, 0.12), ("Stripe2", SILVER, -0.9, 0.05)]
    return tallit("ofit_tallit_royal", "2447B8", st, [("Stripe", WHITE), ("Stripe", WHITE)], SILVER)


def tallit_gold():
    st = [("Stripe", GOLD, -0.5, 0.1), ("Stripe", GOLD, -0.68, 0.06), ("Stripe", GOLD, -0.84, 0.1)]
    return tallit("ofit_tallit_gold", "FBF6E6", st, [("Stripe", GOLD), ("Stripe", GOLD)], GOLD, rough=0.3, fringe=GOLD_L)


def tallit_rainbow():
    cols = [("Stripe", "FFB3BA"), ("Stripe2", "FFD9A8"), ("Stripe3", "FFF2A8"), ("Stripe4", "BDF0C0"),
            ("Stripe5", "B3D9FF"), ("Stripe6", "D9C2FF")]
    st = [(k, h, -0.38 - 0.1 * i, 0.09) for i, (k, h) in enumerate(cols)]
    sh = [cols[0], cols[2], cols[4]]
    return tallit("ofit_tallit_rainbow", "FFF7EA", st, sh, "FFD966")


def tallit_stone():
    st = [("Stripe", "B8935A", -0.62, 0.1), ("Stripe", "B8935A", -0.82, 0.1)]
    return tallit("ofit_tallit_stone", "F1E6CC", st, [("Stripe", "B8935A"), ("Stripe", "B8935A")], GOLD, pattern=pat_stone)


def tallit_stars():
    st = [("Stripe", "C9D2EE", -0.62, 0.08), ("Stripe", "C9D2EE", -0.8, 0.08)]
    return tallit("ofit_tallit_stars", "16224F", st, [("Stripe", "C9D2EE"), ("Stripe", "C9D2EE")], GOLD, pattern=pat_stars)


KC = (0, 0.08, 0.5)
KR = (-12, 0, 0)
KMAT = xf(KC, KR)


def kp(local):
    v = KMAT @ Vector(local)
    return (v.x, v.y, v.z)


def kdome(t, key, hexs, r, h, z=0.0, seg=20, steps=4, **kw):
    dome(t, "Head." + key, hexs, kp((0, 0, z)), r, h, seg=seg, rot=KR, steps=steps, **kw)


def kring(t, key, hexs, R, tr, z, seg=22, rseg=5, **kw):
    t.torus("Head." + key, hexs, kp((0, 0, z)), R, tr, seg=seg, rseg=rseg, rot=KR, **kw)


def ksurf(r, h, a, p, lift=0.0):
    a = math.radians(a)
    p = math.radians(p)
    loc = Vector((r * math.cos(a) * math.cos(p), r * math.cos(a) * math.sin(p), h * math.sin(a)))
    nl = Vector((math.cos(a) * math.cos(p) / r, math.cos(a) * math.sin(p) / r, math.sin(a) / h)).normalized()
    pos = KMAT @ (loc + nl * lift)
    nrm = KMAT.to_3x3() @ nl
    return pos, nrm


def kwedge(t, key, hexs, r, h, p0, p1, steps=5, sub=2, **kw):
    bm = t.bm("Head." + key, hexs, **kw)
    rows = []
    for i in range(steps):
        a = 90.0 * i / steps
        rows.append([bm.verts.new(ksurf(r, h, a, p0 + (p1 - p0) * j / sub)[0]) for j in range(sub + 1)])
    apex = bm.verts.new(ksurf(r, h, 90, 0)[0])
    for i in range(steps - 1):
        for j in range(sub):
            f = bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
            f.smooth = True
    for j in range(sub):
        f = bm.faces.new((rows[steps - 1][j], rows[steps - 1][j + 1], apex))
        f.smooth = True


def kippah_rainbowknit():
    t = new("ofit_kippah_rainbowknit", 0.8)
    r, h = 0.6, 0.3
    kdome(t, "Base", "FFF4DC", r, h, steps=5)
    cols = [("Ring1", "FF6B6B"), ("Ring2", "FFA94D"), ("Ring3", "FFE066"), ("Ring4", "69DB7C"), ("Ring5", "4DABF7")]
    for i, (key, hx) in enumerate(cols):
        a = math.radians(4 + i * 16)
        kring(t, key, hx, r * math.cos(a) + 0.01, 0.06, h * math.sin(a), seg=22, rseg=5)
    a = math.radians(4 + 5 * 16)
    kring(t, "Ring6", "B197FC", r * math.cos(a) + 0.01, 0.055, h * math.sin(a), seg=16, rseg=5)
    t.sphere("Head.Top", "FF6B9A", kp((0, 0, h + 0.02)), 0.1, u=8, v=5)
    return t


def kippah_goldvelvet():
    t = new("ofit_kippah_goldvelvet", 0.85)
    r, h = 0.53, 0.26
    kdome(t, "Base", "6E1A36", r, h, steps=5)
    gold = dict(metal=0.6, rough=0.3)
    kring(t, "Trim", GOLD, r + 0.005, 0.04, 0.0, seg=24, rseg=5, **gold)
    kring(t, "Trim", GOLD, r * math.cos(math.radians(22)) + 0.005, 0.022, h * math.sin(math.radians(22)), seg=24, rseg=4, **gold)
    for i in range(12):
        pos, nrm = ksurf(r, h, 11, i * 30 + 15, 0.01)
        t.sphere("Head.Trim", GOLD_L, pos, 0.032, u=6, v=4, **gold)
    pos, nrm = ksurf(r, h, 90, 0, 0.012)
    mstar(t, "Head.Star", GOLD, align_z(pos, nrm), 0.17, 0.045, bevel=0.012, **gold)
    return t


def kippah_starry():
    t = new("ofit_kippah_starry")
    r, h = 0.54, 0.26
    kdome(t, "Base", "1B2766", r, h, steps=5)
    kring(t, "Trim", SILVER, r + 0.005, 0.03, 0.0, seg=24, rseg=5, metal=0.5, rough=0.3)
    rows = [(16, 8, 10.0, 0.065), (40, 5, 30.0, 0.06), (64, 3, 60.0, 0.055)]
    for a, n, off, rr in rows:
        for i in range(n):
            pos, nrm = ksurf(r, h, a, off + i * 360.0 / n, 0.012)
            mstar(t, "Head.Star", WHITE, align_z(pos, nrm, spin=i * 17), rr, 0.02)
    pos, nrm = ksurf(r, h, 90, 0, 0.012)
    mstar(t, "Head.Top", GOLD_L, align_z(pos, nrm), 0.1, 0.03)
    return t


def kippah_stripes():
    t = new("ofit_kippah_stripes")
    r, h = 0.54, 0.26
    for i in range(12):
        key, hx = ("Base", "2F6FE0") if i % 2 == 0 else ("Stripe", WHITE)
        kwedge(t, key, hx, r, h, i * 30.0, (i + 1) * 30.0)
    kring(t, "Base", "2F6FE0", r + 0.005, 0.035, 0.0, seg=24, rseg=5)
    t.sphere("Head.Top", GOLD, kp((0, 0, h + 0.01)), 0.075, u=8, v=5, metal=0.5, rough=0.3)
    return t


def kippah_emerald():
    t = new("ofit_kippah_emerald", 0.8)
    r, h = 0.54, 0.26
    kdome(t, "Base", "1FA463", r, h, steps=5)
    gold = dict(metal=0.6, rough=0.3)
    kring(t, "Trim", GOLD, r + 0.005, 0.04, 0.0, seg=24, rseg=5, **gold)
    for i in range(8):
        pos, nrm = ksurf(r, h, 30, i * 45.0, 0.01)
        prism(t, "Head.Trim", GOLD_L, [(0, 0.075), (-0.05, 0), (0, -0.075), (0.05, 0)], 0.025, align_z(pos, nrm, spin=i * 45.0 + 90), bevel=0.0, **gold)
    t.sphere("Head.Top", "E8FFF1", kp((0, 0, h + 0.02)), 0.085, u=8, v=5, rough=0.2)
    return t


def kippah_purple():
    t = new("ofit_kippah_purple", 0.8)
    r, h = 0.54, 0.26
    kdome(t, "Base", "7B4DD6", r, h, steps=5)
    kdome(t, "Mid", "A98BF0", 0.3, 0.3, steps=4, seg=16)
    kring(t, "Trim", SILVER, r + 0.005, 0.04, 0.0, seg=24, rseg=5, metal=0.5, rough=0.3)
    for i in range(10):
        pos, nrm = ksurf(r, h, 22, i * 36.0, 0.012)
        t.sphere("Head.Accent", "F3E8FF", pos, 0.035, u=6, v=4, rough=0.25)
    t.sphere("Head.Top", WHITE, kp((0, 0, 0.3 + 0.02)), 0.075, u=8, v=5, rough=0.2)
    return t


def cape_fn(u, v):
    w = 0.97 + 0.8 * (v ** 1.2)
    zb = -2.9 + 0.18 * u * u
    z = 0.92 + (zb - 0.92) * v
    y = 0.68 + 0.5 * (v ** 1.4) - 0.3 * u * u * (0.35 + 0.65 * v) + 0.06 * math.sin(u * 4.4) * v
    return (u * w, y, z)


def cape(name, base, trim, clasp_gem, stars=None, rough=0.55, metal=0.0, trim_metal=0.4):
    t = new(name, rough)
    kw = dict(metal=metal) if metal else {}
    grid_shell(t, "UpperTorso.Base", base, cape_fn, 18, 12, 0.07, u0=-0.985, u1=0.985, v0=0.0, v1=0.99, **kw)
    tk = dict(metal=trim_metal, rough=0.35)
    grid_shell(t, "UpperTorso.Trim", trim, cape_fn, 18, 1, 0.074, off=0.014, u0=-1.0, u1=1.0, v0=0.94, v1=1.0, **tk)
    for a, b in ((-1.0, -0.91), (0.91, 1.0)):
        grid_shell(t, "UpperTorso.Trim", trim, cape_fn, 1, 12, 0.074, off=0.014, u0=a, u1=b, v0=0.0, v1=1.0, **tk)
    for sx in (-1, 1):
        t.box("UpperTorso.Base", base, (sx * 0.62, 0.05, 0.99), (0.9, 1.3, 0.14), bevel=0.06, rot=(0, sx * 8, 0), **kw)
    t.box("UpperTorso.Trim", trim, (0, 0.67, 0.99), (0.3, 0.16, 0.16), bevel=0.05, **tk)
    chain = [(-0.62, -0.58, 0.93), (-0.3, -0.64, 0.8), (0.0, -0.66, 0.76), (0.3, -0.64, 0.8), (0.62, -0.58, 0.93)]
    tube(t, "UpperTorso.Trim", trim, chain, 0.04, seg=6, **tk)
    t.cyl("UpperTorso.Trim", trim, (0, -0.68, 0.76), 0.17, 0.07, seg=16, rot=(90, 0, 0), **tk)
    t.sphere("UpperTorso.Gem", clasp_gem, (0, -0.73, 0.76), 0.085, u=10, v=6, rough=0.15)
    if stars:
        rnd = random.Random(9)
        for u, v in scatter(21, 20, (-0.8, 0.8), (0.12, 0.88), 0.27):
            p = Vector(cape_fn(u, v))
            M = align_z((p.x, p.y + 0.012, p.z), (0, 1, 0), spin=rnd.uniform(0, 60))
            mstar(t, "UpperTorso.Star", stars, M, 0.075 + 0.05 * v, 0.024)
    return t


def cape_royal():
    return cape("ofit_cape_royal", "2447B8", GOLD, "FFFFFF", metal=0.0)


def cape_gold():
    return cape("ofit_cape_gold", "F2B632", "F6F6FA", SKY, rough=0.35, metal=0.35, trim_metal=0.1)


def cape_starry():
    return cape("ofit_cape_starry", "16224F", SILVER, GOLD, stars=WHITE)


def feather(t, key, hexs, P0, d, r0, L, w, th, yoff):
    d = Vector(d).normalized()
    c = Vector(P0) + d * (r0 + L / 2) + Vector((0, yoff, 0))
    e = Vector((0, 0, 1)).rotation_difference(d).to_euler('XYZ')
    t.sphere("UpperTorso." + key, hexs, (c.x, c.y, c.z), 1.0, u=8, v=5, scale=(w / 2, th / 2, L / 2),
             rot=(math.degrees(e.x), math.degrees(e.y), math.degrees(e.z)))


def wings(name, cols, trim, rough=0.45):
    t = new(name, rough)
    rows = [
        ("Base", [28, 46, 64, 82, 100], [1.55, 1.75, 1.8, 1.65, 1.4], 0.42, 0.0),
        ("Mid", [18, 38, 58, 78, 98, 118], [1.0, 1.2, 1.28, 1.2, 1.05, 0.85], 0.42, 0.07),
        ("Top", [8, 32, 56, 80, 104, 128], [0.6, 0.78, 0.85, 0.8, 0.66, 0.5], 0.4, 0.14),
    ]
    for sx in (-1, 1):
        P0 = (sx * 0.42, 0.74, 0.5)
        for key, angs, lens, w, yoff in rows:
            for a, L in zip(angs, lens):
                ar = math.radians(a)
                feather(t, key, cols[key], P0, (sx * math.sin(ar), 0.2, math.cos(ar)), 0.05, L, w, 0.12, yoff)
        t.sphere("UpperTorso.Trim", trim, P0, 0.28, u=12, v=8, scale=(1.0, 0.8, 1.1))
        t.box("UpperTorso.Trim", trim, (sx * 0.42, 0.62, 0.45), (0.6, 0.14, 0.7), bevel=0.07)
    return t


def wings_dove():
    return wings("ofit_wings_dove", {"Base": "E3EAF6", "Mid": "F1F5FC", "Top": "FFFFFF"}, "C9D6F0")


def wings_gold():
    return wings("ofit_wings_gold", {"Base": GOLD, "Mid": CREAM, "Top": GOLD_L}, GOLD_D, rough=0.35)


def straps(t, hexs, buckle=GOLD):
    for sx in (-1, 1):
        t.box("UpperTorso.Strap", hexs, (sx * 0.6, 0.0, 0.99), (0.26, 1.3, 0.12), bevel=0.05)
        t.box("UpperTorso.Strap", hexs, (sx * 0.6, -0.6, 0.35), (0.26, 0.1, 1.3), bevel=0.04)
        t.box("UpperTorso.Strap", hexs, (sx * 0.6, 0.6, 0.3), (0.26, 0.1, 1.4), bevel=0.04)
        t.box("UpperTorso.Trim", buckle, (sx * 0.6, -0.63, -0.35), (0.2, 0.06, 0.2), bevel=0.02, metal=0.6, rough=0.3)


def pack_satchel():
    t = new("ofit_pack_satchel", 0.6)
    straps(t, LEATHER_D)
    t.box("UpperTorso.Base", LEATHER, (0, 0.98, -0.2), (1.55, 0.68, 1.3), bevel=0.2)
    for sx in (-1, 1):
        t.box("UpperTorso.Base", LEATHER, (sx * 0.84, 0.98, -0.62), (0.3, 0.56, 0.55), bevel=0.1)
    t.box("UpperTorso.Mid", LEATHER_L, (0, 0.98, 0.45), (1.6, 0.74, 0.16), bevel=0.08)
    t.box("UpperTorso.Mid", LEATHER_L, (0, 1.34, 0.0), (1.6, 0.1, 0.95), bevel=0.05)
    for sx in (-1, 1):
        t.box("UpperTorso.Strap", LEATHER_D, (sx * 0.5, 1.395, -0.05), (0.1, 0.03, 0.85), bevel=0.0)
    M = align_z((0, 1.43, -0.2), (0, 1, 0))
    mstar(t, "UpperTorso.Trim", GOLD, M, 0.2, 0.07, bevel=0.015, metal=0.6, rough=0.3)
    t.sphere("UpperTorso.Gem", SKY, (0, 1.47, -0.2), 0.06, u=8, v=5, rough=0.15)
    return t


def loaf(t, c, length, tilt=0.0):
    t.sphere("UpperTorso.Bread", "E6A23C", c, 1.0, u=12, v=8, scale=(length / 2, 0.3, 0.25), rot=(0, tilt, 0))
    n = 6
    for i in range(n):
        x = -length * 0.38 + i * (length * 0.76) / (n - 1)
        s = 1 if i % 2 == 0 else -1
        t.sphere("UpperTorso.Braid", "F5C25B", (c[0] + x, c[1] + 0.2, c[2] + s * 0.08), 1.0, u=8, v=5,
                 scale=(0.2, 0.13, 0.1), rot=(0, s * 35, 0))


def pack_challah():
    t = new("ofit_pack_challah", 0.7)
    straps(t, "C79A5B")
    prof = [(0, 0), (0.62, 0), (0.78, 0.12), (0.88, 0.8), (0.8, 0.8), (0.72, 0.18), (0, 0.15)]
    t.lathe("UpperTorso.Base", "D9A85C", (0, 0.62, -0.1), prof, seg=28, rot=(-90, 0, 0))
    for z in (0.28, 0.46, 0.64):
        rr = 0.78 + 0.1 * (z - 0.12) / 0.68 + 0.012
        t.torus("UpperTorso.Mid", "B07F3A", (0, 0.62 + z, -0.1), rr, 0.035, seg=28, rseg=5, rot=(90, 0, 0))
    t.torus("UpperTorso.Mid", "B07F3A", (0, 1.44, -0.1), 0.86, 0.06, seg=28, rseg=6, rot=(90, 0, 0))
    loaf(t, (0.0, 1.18, 0.14), 1.3, 4)
    loaf(t, (0.0, 1.16, -0.38), 1.25, -4)
    t.box("UpperTorso.Cloth", "3F78E8", (0, 1.5, -0.86), (1.35, 0.07, 0.62), bevel=0.025, rot=(-18, 0, 0))
    R = Matrix.Rotation(math.radians(-18), 3, 'X')
    for dz in (-0.17, 0.17):
        c = Vector((0, 1.5, -0.86)) + R @ Vector((0, 0.045, dz))
        t.box("UpperTorso.Stripe", WHITE, (c.x, c.y, c.z), (1.37, 0.03, 0.1), bevel=0.0, rot=(-18, 0, 0))
    return t


def pack_candles():
    t = new("ofit_pack_candles", 0.35)
    brass = dict(metal=0.7, rough=0.28)
    straps(t, NAVY)
    t.box("UpperTorso.Mid", "2F4FB5", (0, 0.68, -0.05), (1.5, 0.2, 1.7), bevel=0.09)
    mstar(t, "UpperTorso.Trim", GOLD_L, align_z((0, 0.81, 0.3), (0, 1, 0)), 0.22, 0.05, bevel=0.012, **brass)
    t.sphere("UpperTorso.Gem", SKY, (0, 0.86, 0.3), 0.07, u=8, v=5, rough=0.15)
    t.box("UpperTorso.Base", GOLD, (0, 1.0, -0.74), (1.5, 0.7, 0.14), bevel=0.06, **brass)
    zb = -0.67
    for x in (-0.4, 0.4):
        t.cyl("UpperTorso.Base", GOLD, (x, 1.0, zb + 0.05), 0.22, 0.1, seg=16, r2=0.17, **brass)
        t.cyl("UpperTorso.Base", GOLD, (x, 1.0, zb + 0.33), 0.07, 0.5, seg=10, **brass)
        t.sphere("UpperTorso.Base", GOLD_L, (x, 1.0, zb + 0.22), 0.12, u=10, v=6, **brass)
        t.sphere("UpperTorso.Base", GOLD_L, (x, 1.0, zb + 0.45), 0.1, u=10, v=6, **brass)
        t.cyl("UpperTorso.Base", GOLD_L, (x, 1.0, zb + 0.66), 0.09, 0.16, seg=12, r2=0.16, **brass)
        t.cyl("UpperTorso.Candle", CREAM, (x, 1.0, zb + 0.98), 0.08, 0.55, seg=10)
        t.sphere("UpperTorso.Glow", FLAME, (x, 1.0, zb + 1.43), 0.1, u=8, v=6, scale=(0.9, 0.9, 1.7), emit=1.0)
    return t


def flower(t, pos, nrm, key, hexs, spin, s=1.0):
    M = align_z(pos, nrm, spin)
    e = edeg(M)
    for k in range(5):
        a = math.radians(72 * k)
        c = M @ Vector((math.cos(a) * 0.15 * s, math.sin(a) * 0.15 * s, 0.0))
        t.sphere("Head." + key, hexs, (c.x, c.y, c.z), 0.13 * s, u=6, v=4, scale=(1, 1, 0.6), rot=e)
    c = M @ Vector((0, 0, 0.05 * s))
    t.sphere("Head.Center", GOLD_L, (c.x, c.y, c.z), 0.1 * s, u=6, v=4)


def hat_flowers():
    t = new("ofit_hat_flowers", 0.6)
    R = 0.66
    cy = 0.02
    t.torus("Head.Leaf", "4FB45A", (0, cy, 0.38), R, 0.06, seg=30, rseg=5)
    cols = [("Petal", "FF7FAE"), ("Petal2", "FFD84D"), ("Petal3", "B493FF"), ("Petal4", "FF9A62")]
    n = 9
    for k in range(n):
        phi = math.radians(-90 + k * 360.0 / n)
        pos = (R * math.cos(phi), cy + R * math.sin(phi), 0.4 + 0.04 * math.sin(2 * phi))
        nrm = (math.cos(phi) * 0.85, math.sin(phi) * 0.85, 0.5)
        key, hx = cols[k % 4]
        flower(t, pos, nrm, key, hx, k * 25.0, 1.15 if k == 0 else 1.0)
        phi2 = phi + math.radians(180.0 / n)
        t.sphere("Head.Leaf", "4FB45A", (R * math.cos(phi2), cy + R * math.sin(phi2), 0.36), 1.0, u=6, v=4,
                 scale=(0.22, 0.1, 0.07), rot=(0, 0, math.degrees(phi2) + 90))
    for sx in (-1, 1):
        t.box("Head.Ribbon", "FF9EC4", (sx * 0.1, 0.72, 0.1), (0.14, 0.04, 0.7), bevel=0.02, rot=(0, 0, sx * 8))
    return t


def hat_crown():
    t = new("ofit_hat_crown", 0.35)
    gold = dict(metal=0.6, rough=0.3)
    z0 = 0.36
    cy = 0.02
    ring_band(t, "Head.Base", GOLD, (0, cy, z0), 0.62, 0.72, 0.28, seg=28, **gold)
    t.torus("Head.Trim", GOLD_L, (0, cy, z0 + 0.01), 0.72, 0.04, seg=28, rseg=5, **gold)
    t.torus("Head.Trim", GOLD_L, (0, cy, z0 + 0.27), 0.72, 0.04, seg=28, rseg=5, **gold)
    for k in range(6):
        a = 2 * math.pi * k / 6 - math.pi / 2
        x, y = math.cos(a) * 0.69, cy + math.sin(a) * 0.69
        t.cyl("Head.Base", GOLD, (x, y, z0 + 0.5), 0.14, 0.44, seg=8, r2=0.03, **gold)
        key, hx = ("Gem", "2F6FE0") if k % 2 == 0 else ("Gem2", WHITE)
        t.sphere("Head." + key, hx, (x, y, z0 + 0.76), 0.085, u=8, v=5, rough=0.15)
        a2 = a + math.pi / 6
        x2, y2 = math.cos(a2) * 0.69, cy + math.sin(a2) * 0.69
        t.cyl("Head.Base", GOLD, (x2, y2, z0 + 0.4), 0.1, 0.24, seg=8, r2=0.04, **gold)
        t.sphere("Head.Gem2", WHITE, (x2, y2, z0 + 0.54), 0.055, u=6, v=4, rough=0.15)
        key3, hx3 = ("Gem2", WHITE) if k % 2 == 0 else ("Gem", "2F6FE0")
        a3 = a + math.pi / 6
        t.sphere("Head." + key3, hx3, (math.cos(a3) * 0.73, cy + math.sin(a3) * 0.73, z0 + 0.14), 0.07, u=8, v=5, scale=(1, 1, 1.1), rough=0.15)
    return t


def topz(r):
    pts = [(0.6, 0.02), (0.9, 0.0), (1.2, -0.08), (1.38, -0.22)]
    for (r0, z0), (r1, z1) in zip(pts, pts[1:]):
        if r0 <= r <= r1:
            return z0 + (z1 - z0) * (r - r0) / (r1 - r0)
    return pts[-1][1]


def hat_sunhat():
    t = new("ofit_hat_sunhat", 0.8)
    z0 = 0.3
    cy = 0.02
    brim = [(0.6, 0.02), (0.9, 0.0), (1.2, -0.08), (1.38, -0.22), (1.38, -0.27), (1.2, -0.13), (0.9, -0.05), (0.6, -0.03), (0.6, 0.02)]
    t.lathe("Head.Base", STRAW, (0, cy, z0), brim, seg=36)
    crown = [(0.64, 0.0), (0.7, 0.14), (0.68, 0.3), (0.56, 0.46), (0.3, 0.56), (0.0, 0.58)]
    t.lathe("Head.Base", STRAW, (0, cy, z0), crown, seg=30)
    for r in (0.82, 1.02, 1.24):
        t.torus("Head.Mid", STRAW_D, (0, cy, z0 + topz(r) + 0.012), r, 0.028, seg=34, rseg=4)
    t.torus("Head.Mid", STRAW_D, (0, cy, z0 + 0.3), 0.69, 0.028, seg=28, rseg=4)
    t.torus("Head.Mid", STRAW_D, (0, cy, z0 + 0.43), 0.59, 0.028, seg=26, rseg=4)
    ring_band(t, "Head.Ribbon", "3F78E8", (0, cy, z0 + 0.02), 0.62, 0.72, 0.17, seg=30)
    bx = 0.74
    bz = z0 + 0.1
    for sy in (-1, 1):
        t.sphere("Head.Ribbon", "3F78E8", (bx, cy + sy * 0.2, bz), 1.0, u=10, v=6, scale=(0.07, 0.19, 0.12))
        t.box("Head.Ribbon", "3F78E8", (bx + 0.2, cy + sy * 0.13, z0 + 0.03), (0.42, 0.12, 0.035), bevel=0.012, rot=(0, 0, -sy * 14))
    t.sphere("Head.Knot", "2A56B8", (bx + 0.01, cy, bz), 0.09, u=8, v=5)
    return t


def glasses_gold():
    t = new("ofit_glasses_gold", 0.3)
    gold = dict(metal=0.8, rough=0.25)
    y = -0.655
    for sx in (-1, 1):
        t.torus("Head.Frame", GOLD, (sx * 0.3, y, 0.1), 0.23, 0.03, seg=24, rseg=6, rot=(90, 0, 0), **gold)
        tube(t, "Head.Frame", GOLD, [(sx * 0.52, y + 0.01, 0.12), (sx * 0.62, -0.5, 0.12), (sx * 0.63, -0.1, 0.1), (sx * 0.62, 0.15, 0.0)], 0.026, seg=6, **gold)
    tube(t, "Head.Frame", GOLD, [(-0.08, y, 0.15), (0.0, y - 0.025, 0.19), (0.08, y, 0.15)], 0.026, seg=6, **gold)
    return t


def bowtie_blue():
    t = new("ofit_bowtie_blue", 0.45)
    z = 0.66
    for sx in (-1, 1):
        pts = [(sx * 0.07, z + 0.07), (sx * 0.5, z + 0.25), (sx * 0.5, z - 0.25), (sx * 0.07, z - 0.07)]
        t.poly("UpperTorso.Cloth", "3F78E8", pts[::sx], -0.7, -0.58, bevel=0.04, plane="XZ")
        for dx, dz in ((0.25, 0.04), (0.36, -0.08), (0.18, -0.07)):
            t.sphere("UpperTorso.Dot", WHITE, (sx * dx, -0.715, z + dz), 0.035, u=6, v=4)
    t.box("UpperTorso.Knot", "2A56B8", (0, -0.65, z), (0.2, 0.15, 0.24), bevel=0.06)
    return t


BUILDERS = {
    "tallit_royal": tallit_royal, "tallit_gold": tallit_gold, "tallit_rainbow": tallit_rainbow,
    "tallit_stone": tallit_stone, "tallit_stars": tallit_stars,
    "kippah_rainbowknit": kippah_rainbowknit, "kippah_goldvelvet": kippah_goldvelvet, "kippah_starry": kippah_starry,
    "kippah_stripes": kippah_stripes, "kippah_emerald": kippah_emerald, "kippah_purple": kippah_purple,
    "cape_royal": cape_royal, "cape_gold": cape_gold, "cape_starry": cape_starry,
    "wings_dove": wings_dove, "wings_gold": wings_gold,
    "pack_satchel": pack_satchel, "pack_challah": pack_challah, "pack_candles": pack_candles,
    "hat_flowers": hat_flowers, "hat_crown": hat_crown, "hat_sunhat": hat_sunhat,
    "glasses_gold": glasses_gold, "bowtie_blue": bowtie_blue,
}

BACKVIEW = {"cape_royal", "cape_gold", "cape_starry", "wings_dove", "wings_gold", "pack_satchel", "pack_challah", "pack_candles"}


def attach_of(name):
    first = name.split("_")[0]
    if first in ("kippah", "hat", "glasses"):
        return "Head"
    return "UpperTorso"


def ghost(att):
    t = Toy("ghost", rough=0.8)
    c = "8D99B8"
    z = 0.0 if att == "UpperTorso" else -1.6

    def b(cx, cy, cz, sx, sy, sz, bev=0.15):
        t.box("Ghost", c, (cx, cy, cz + z), (sx, sy, sz), bevel=bev)

    b(0, 0, 0, 1.84, 1.07, 1.9, 0.3)
    b(0, 0, 1.6, 1.2, 1.2, 1.2, 0.3)
    b(0, 0, -1.27, 1.67, 1.04, 0.63, 0.15)
    for sx in (-1, 1):
        b(sx * 1.39, 0, 0.34, 0.94, 0.76, 1.21, 0.25)
        b(sx * 1.39, 0, -0.85, 0.81, 0.9, 1.16, 0.25)
        b(sx * 0.42, 0, -2.5, 0.8, 0.9, 1.3)
        b(sx * 0.42, 0, -3.8, 0.75, 0.85, 1.3)
        t.sphere("GhostEye", "3A4256", (sx * 0.27, -0.6, 1.7 + z), 0.07, u=8, v=5)
    return t.finish()


def build_cosmetics(names=None, do_export=True, preview=False):
    out = {}
    for name in (names or list(BUILDERS)):
        reset()
        toy = BUILDERS[name]()
        objs = toy.finish()
        mn, mx = bounds(objs)
        keys = sorted(o.name.replace("__", "=") for o in objs if "__" in o.name)
        entry = {"tris": tris(objs), "min": [round(v, 2) for v in mn], "max": [round(v, 2) for v in mx], "keys": keys}
        if do_export:
            entry.update(export("ofit_" + name, objs))
        if preview:
            g = ghost(attach_of(name))
            d = (0.55, 1.0, 0.4) if name in BACKVIEW else (0.55, -1.0, 0.45)
            render_icon(objs, "ofit_" + name, size=384, direction=d, pad=1.2)
        out[name] = entry
    return out
