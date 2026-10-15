import os
from collections import defaultdict

AUDIT_NO_RUN = True
exec(open("tools/blender/zfight_audit.py").read())

MIN_SEPARATION = 0.12
FIGHT_GAP = 0.04
ROUNDS = 3


def polygon_areas():
    areas = {}
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            areas[obj.name] = [p.area for p in obj.data.polygons]
    return areas


def find_moves():
    triangles = collect_triangles()
    areas = polygon_areas()
    buckets = defaultdict(list)
    for index, t in enumerate(triangles):
        n = t[4]
        key = (round(n.x, 2) + 0.0, round(n.y, 2) + 0.0, round(n.z, 2) + 0.0, round(n.dot(t[1]) / 0.1))
        buckets[key].append(index)
    box = [bounds(t) for t in triangles]
    moves = defaultdict(float)

    def consider(first, second, same_bucket):
        for i in first:
            for j in second:
                if same_bucket and j <= i:
                    continue
                a, b = triangles[i], triangles[j]
                if a[0] == b[0] or a[4].dot(b[4]) < SAME_DIRECTION:
                    continue
                gap = abs(a[4].dot(a[1]) - b[4].dot(b[1]))
                if gap >= FIGHT_GAP or not boxes_touch(box[i], box[j], FIGHT_GAP):
                    continue
                if overlap_area(a, b) < MIN_AREA:
                    continue
                if a[4].z < -0.9 and abs(a[1].z - 1.0) < 0.02:
                    continue
                area_a = areas[a[0]][a[6]]
                area_b = areas[b[0]][b[6]]
                if area_a < area_b or (area_a == area_b and a[0] > b[0]):
                    mover, other = a, b
                else:
                    mover, other = b, a
                signed = mover[4].dot(mover[1] - other[1])
                delta = MIN_SEPARATION - signed
                if delta > 0:
                    key = (mover[0], mover[6])
                    moves[key] = max(moves[key], delta)

    for key, members in buckets.items():
        consider(members, members, True)
        neighbor = (key[0], key[1], key[2], key[3] + 1)
        if neighbor in buckets:
            consider(members, buckets[neighbor], False)
    return moves


def apply_moves(moves):
    per_object = defaultdict(dict)
    for (name, poly), delta in moves.items():
        per_object[name][poly] = delta
    worst = 0.0
    for name, polys in per_object.items():
        obj = bpy.data.objects[name]
        mesh = obj.data
        displacement = defaultdict(float)
        for poly_index, delta in polys.items():
            polygon = mesh.polygons[poly_index]
            normal = polygon.normal
            nkey = (round(normal.x, 2) + 0.0, round(normal.y, 2) + 0.0, round(normal.z, 2) + 0.0)
            for vertex in polygon.vertices:
                key = (vertex, nkey)
                displacement[key] = max(displacement[key], delta)
        for (vertex, nkey), delta in displacement.items():
            mesh.vertices[vertex].co += Vector(nkey) * delta
            worst = max(worst, delta)
        mesh.update()
        mesh.calc_normals_split() if hasattr(mesh, "calc_normals_split") else None
    return worst


def export_fbx(path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type == "MESH" and not obj.hide_viewport:
            obj.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_NONE",
        global_scale=1.0,
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        bake_anim=False,
    )


before = audit()
history = []
for round_index in range(ROUNDS):
    moves = find_moves()
    if not moves:
        break
    worst = apply_moves(moves)
    history.append({"round": round_index + 1, "polygonsMoved": len(moves), "maxPush": round(worst, 3)})
after = audit()

target = os.environ.get("FIX_EXPORT")
if target and after["fightPairs"] <= before["fightPairs"]:
    export_fbx(target)
    bpy.ops.wm.save_mainfile()

result = {
    "file": before["file"],
    "fightBefore": before["fightPairs"],
    "fightAfter": after["fightPairs"],
    "nearBefore": before["nearPairs"],
    "nearAfter": after["nearPairs"],
    "rounds": history,
    "remaining": [r for r in after["top"] if r["kind"] == "FIGHT"],
    "exported": bool(target) and after["fightPairs"] <= before["fightPairs"],
}
