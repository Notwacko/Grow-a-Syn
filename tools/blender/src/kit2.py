import bpy
import bmesh
import math
import os
from mathutils import Matrix, Vector

ART = "/Users/wacko/Documents/growasyn/art"
EXP = ART + "/exports"
SRC = ART + "/src"
ICONS = ART + "/icons"
MARKER_HEX = "8C8C8C"


def reset():
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
    for c in list(bpy.data.cameras):
        bpy.data.cameras.remove(c)
    for l in list(bpy.data.lights):
        bpy.data.lights.remove(l)


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def mat(hexs, rough=0.42, metal=0.0, emit=0.0):
    name = "M_%s_%d_%d_%d" % (hexs, int(rough * 100), int(metal * 100), int(emit * 100))
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    r, g, b = (int(hexs[i:i + 2], 16) / 255 for i in (0, 2, 4))
    col = (lin(r), lin(g), lin(b), 1.0)
    m.diffuse_color = col
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    if p:
        p.inputs["Base Color"].default_value = col
        p.inputs["Roughness"].default_value = rough
        p.inputs["Metallic"].default_value = metal
        if emit > 0:
            p.inputs["Emission Color"].default_value = col
            p.inputs["Emission Strength"].default_value = emit
    return m


def xf(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    T = Matrix.Translation(Vector(loc))
    R = (Matrix.Rotation(math.radians(rot[2]), 4, 'Z') @
         Matrix.Rotation(math.radians(rot[1]), 4, 'Y') @
         Matrix.Rotation(math.radians(rot[0]), 4, 'X'))
    S = Matrix.Diagonal(Vector((scale[0], scale[1], scale[2], 1.0)))
    return T @ R @ S


class Toy:
    def __init__(self, model, rough=0.42):
        self.model = model
        self.rough = rough
        self.parts = {}
        self.order = []
        self.markers = []
        self.objs = []

    def bm(self, label, hexs, rough=None, metal=0.0, emit=0.0):
        key = (label, hexs.upper(), rough if rough is not None else self.rough, metal, emit)
        if key not in self.parts:
            self.parts[key] = bmesh.new()
            self.order.append(key)
        return self.parts[key]

    def _bevel(self, bm, geom_verts, amount, segments=2):
        if amount <= 0:
            return
        vs = set(geom_verts)
        faces = list({f for v in vs for f in v.link_faces if all(x in vs for x in f.verts)})
        bmesh.ops.recalc_face_normals(bm, faces=faces)
        bm.normal_update()
        edges = [e for v in vs for e in v.link_edges if e.verts[0] in vs and e.verts[1] in vs]
        edges = list(set(edges))
        sharp = []
        for e in edges:
            if len(e.link_faces) == 2:
                a, b = e.link_faces
                if a.normal.length > 0 and b.normal.length > 0 and a.normal.angle(b.normal) > math.radians(30):
                    sharp.append(e)
            else:
                sharp.append(e)
        if not sharp:
            return
        res = bmesh.ops.bevel(bm, geom=sharp, offset=amount, offset_type='OFFSET', segments=segments,
                              profile=0.62, affect='EDGES', clamp_overlap=True)
        for f in res.get("faces", []):
            f.smooth = True

    def box(self, label, hexs, c, size, rot=(0, 0, 0), bevel=0.08, **kw):
        bm = self.bm(label, hexs, **kw)
        res = bmesh.ops.create_cube(bm, size=1.0, matrix=xf(c, rot, size))
        self._bevel(bm, res["verts"], min(bevel, min(size) * 0.45))

    def sphere(self, label, hexs, c, r, u=20, v=12, scale=(1, 1, 1), rot=(0, 0, 0), **kw):
        bm = self.bm(label, hexs, **kw)
        res = bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=r, matrix=xf(c, rot, scale))
        for vert in res["verts"]:
            for f in vert.link_faces:
                f.smooth = True

    def cyl(self, label, hexs, c, r, h, seg=24, r2=None, rot=(0, 0, 0), scale=(1, 1, 1), bevel=0.0, **kw):
        bm = self.bm(label, hexs, **kw)
        res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r,
                                    radius2=(r if r2 is None else r2), depth=h, matrix=xf(c, rot, scale))
        verts = res["verts"]
        side = set()
        for vert in verts:
            for f in vert.link_faces:
                if len(f.verts) == 4:
                    side.add(f)
        for f in side:
            f.smooth = True
        if bevel > 0:
            self._bevel(bm, verts, bevel)

    def torus(self, label, hexs, c, R, r, seg=28, rseg=10, rot=(0, 0, 0), **kw):
        bm = self.bm(label, hexs, **kw)
        M = xf(c, rot)
        rings = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ring = []
            for j in range(rseg):
                b = 2 * math.pi * j / rseg
                x = (R + r * math.cos(b)) * math.cos(a)
                y = (R + r * math.cos(b)) * math.sin(a)
                z = r * math.sin(b)
                ring.append(bm.verts.new(M @ Vector((x, y, z))))
            rings.append(ring)
        for i in range(seg):
            n = (i + 1) % seg
            for j in range(rseg):
                k = (j + 1) % rseg
                f = bm.faces.new((rings[i][j], rings[n][j], rings[n][k], rings[i][k]))
                f.smooth = True

    def lathe(self, label, hexs, c, profile, seg=28, rot=(0, 0, 0), scale=(1, 1, 1), smooth=True, **kw):
        bm = self.bm(label, hexs, **kw)
        M = xf(c, rot, scale)
        rings = []
        for (rr, zz) in profile:
            ring = []
            for i in range(seg):
                a = 2 * math.pi * i / seg
                ring.append(bm.verts.new(M @ Vector((rr * math.cos(a), rr * math.sin(a), zz))))
            rings.append(ring)
        for j in range(len(rings) - 1):
            a, b = rings[j], rings[j + 1]
            for i in range(seg):
                n = (i + 1) % seg
                if profile[j][0] == 0 and profile[j + 1][0] == 0:
                    continue
                if profile[j][0] == 0:
                    f = bm.faces.new((a[0], b[n], b[i]))
                elif profile[j + 1][0] == 0:
                    f = bm.faces.new((a[i], a[n], b[0]))
                else:
                    f = bm.faces.new((a[i], a[n], b[n], b[i]))
                f.smooth = smooth

    def poly(self, label, hexs, pts, z0, z1, bevel=0.06, plane="XY", **kw):
        bm = self.bm(label, hexs, **kw)
        if plane == "XY":
            a = [bm.verts.new((x, y, z0)) for x, y in pts]
            b = [bm.verts.new((x, y, z1)) for x, y in pts]
        elif plane == "XZ":
            a = [bm.verts.new((x, z0, z)) for x, z in pts]
            b = [bm.verts.new((x, z1, z)) for x, z in pts]
        else:
            a = [bm.verts.new((z0, y, z)) for y, z in pts]
            b = [bm.verts.new((z1, y, z)) for y, z in pts]
        n = len(pts)
        bm.faces.new(a)
        bm.faces.new(list(reversed(b)))
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
        self._bevel(bm, a + b, bevel)

    def marker(self, name, c, size=(1, 1, 1)):
        self.markers.append((name, tuple(c), tuple(size)))

    def finish(self):
        col = bpy.data.collections.new(self.model)
        bpy.context.scene.collection.children.link(col)
        objs = []
        for key in self.order:
            label, hexs, rough, metal, emit = key
            bm = self.parts[key]
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            me = bpy.data.meshes.new("%s__%s" % (label, hexs))
            bm.to_mesh(me)
            bm.free()
            me.materials.append(mat(hexs, rough, metal, emit))
            ob = bpy.data.objects.new("%s__%s" % (label, hexs), me)
            col.objects.link(ob)
            objs.append(ob)
        for name, c, s in self.markers:
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0, matrix=xf(c, (0, 0, 0), s))
            me = bpy.data.meshes.new(name)
            bm.to_mesh(me)
            bm.free()
            me.materials.append(mat(MARKER_HEX, 0.9))
            ob = bpy.data.objects.new(name, me)
            col.objects.link(ob)
            objs.append(ob)
        self.objs = objs
        return objs


def bounds(objs):
    pts = []
    for o in objs:
        for v in o.bound_box:
            pts.append(o.matrix_world @ Vector(v))
    mn = Vector((min(p[i] for p in pts) for i in range(3)))
    mx = Vector((max(p[i] for p in pts) for i in range(3)))
    return mn, mx


def tris(objs):
    total = 0
    for o in objs:
        me = o.data
        me.calc_loop_triangles()
        total += len(me.loop_triangles)
    return total


def export(model, objs):
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.export_scene.fbx(filepath="%s/%s.fbx" % (EXP, model), use_selection=True,
                             object_types={'MESH'}, apply_unit_scale=True,
                             apply_scale_options='FBX_SCALE_NONE', global_scale=1.0,
                             axis_forward='-Z', axis_up='Y', mesh_smooth_type='FACE',
                             add_leaf_bones=False, bake_anim=False)
    bpy.ops.wm.save_as_mainfile(filepath="%s/%s.blend" % (SRC, model), copy=True)
    mn, mx = bounds(objs)
    return {"tris": tris(objs), "min": [round(v, 2) for v in mn], "max": [round(v, 2) for v in mx]}


def setup_render(size=256):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    try:
        scene.eevee.taa_render_samples = 48
    except Exception:
        pass
    world = bpy.data.worlds.new("W") if not scene.world else scene.world
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (0.86, 0.9, 1.0, 1.0)
        bg.inputs["Strength"].default_value = 0.85
    try:
        scene.view_settings.view_transform = 'Standard'
    except Exception:
        pass


def render_icon(objs, name, size=256, direction=(0.8, -1.0, 0.75), pad=1.22, roll=0):
    setup_render(size)
    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type in {'CAMERA', 'LIGHT'}:
            bpy.data.objects.remove(o, do_unlink=True)
    mn, mx = bounds(objs)
    center = (mn + mx) / 2
    radius = max((mx - mn).length / 2, 0.01)
    cam_data = bpy.data.cameras.new("IconCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = radius * 2 * pad
    cam = bpy.data.objects.new("IconCam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    d = Vector(direction).normalized()
    cam.location = center + d * (radius * 6)
    look = (center - cam.location).to_track_quat('-Z', 'Y')
    cam.rotation_euler = look.to_euler()
    cam.rotation_euler.rotate_axis('Z', math.radians(roll))
    cam_data.clip_end = radius * 30
    scene.camera = cam
    sun_data = bpy.data.lights.new("Key", 'SUN')
    sun_data.energy = 3.4
    sun_data.angle = math.radians(18)
    sun = bpy.data.objects.new("Key", sun_data)
    bpy.context.scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(8), math.radians(32))
    fill_data = bpy.data.lights.new("Fill", 'SUN')
    fill_data.energy = 1.1
    fill = bpy.data.objects.new("Fill", fill_data)
    bpy.context.scene.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(70), math.radians(-12), math.radians(-120))
    os.makedirs(ICONS, exist_ok=True)
    scene.render.filepath = "%s/%s.png" % (ICONS, name)
    bpy.ops.render.render(write_still=True)
    return scene.render.filepath
