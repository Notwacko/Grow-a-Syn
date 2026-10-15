import bpy
import re
from collections import defaultdict
from mathutils import Vector

PLANE_TOL = 0.04
NEAR_TOL = 0.12
SAME_DIRECTION = 0.999
MIN_AREA = 0.05

MARKER = re.compile(r"^(Door|Seat\d+|Slot_.*)$")


def collect_triangles():
    triangles = []
    for obj in bpy.data.objects:
        if obj.type != "MESH" or MARKER.match(obj.name):
            continue
        if obj.hide_viewport or obj.hide_render:
            continue
        mesh = obj.data
        mesh.calc_loop_triangles()
        matrix = obj.matrix_world
        points = [matrix @ vertex.co for vertex in mesh.vertices]
        for loop_triangle in mesh.loop_triangles:
            a, b, c = (points[i] for i in loop_triangle.vertices)
            cross = (b - a).cross(c - a)
            doubled = cross.length
            if doubled < 1e-9:
                continue
            normal = cross / doubled
            triangles.append((obj.name, a, b, c, normal, doubled / 2, loop_triangle.polygon_index))
    return triangles


def basis(normal):
    axis = Vector((1, 0, 0)) if abs(normal.x) < 0.9 else Vector((0, 1, 0))
    u = normal.cross(axis).normalized()
    v = normal.cross(u)
    return u, v


def to_2d(points, u, v):
    return [(p.dot(u), p.dot(v)) for p in points]


def orient(polygon):
    area = 0.0
    for i in range(len(polygon)):
        x1, y1 = polygon[i]
        x2, y2 = polygon[(i + 1) % len(polygon)]
        area += x1 * y2 - x2 * y1
    return polygon if area >= 0 else list(reversed(polygon))


def clip(subject, clipper):
    output = subject
    for i in range(len(clipper)):
        if not output:
            break
        ax, ay = clipper[i]
        bx, by = clipper[(i + 1) % len(clipper)]
        source = output
        output = []
        for j in range(len(source)):
            px, py = source[j]
            qx, qy = source[(j + 1) % len(source)]
            side_p = (bx - ax) * (py - ay) - (by - ay) * (px - ax)
            side_q = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
            if side_p >= 0:
                output.append((px, py))
            if (side_p >= 0) != (side_q >= 0):
                t = side_p / (side_p - side_q)
                output.append((px + (qx - px) * t, py + (qy - py) * t))
    return output


def polygon_area(polygon):
    area = 0.0
    for i in range(len(polygon)):
        x1, y1 = polygon[i]
        x2, y2 = polygon[(i + 1) % len(polygon)]
        area += x1 * y2 - x2 * y1
    return abs(area) / 2


def overlap_area(t1, t2):
    normal = t1[4]
    u, v = basis(normal)
    p1 = orient(to_2d((t1[1], t1[2], t1[3]), u, v))
    p2 = orient(to_2d((t2[1], t2[2], t2[3]), u, v))
    return polygon_area(clip(p1, p2))


def bounds(triangle):
    xs = [triangle[i].x for i in (1, 2, 3)]
    ys = [triangle[i].y for i in (1, 2, 3)]
    zs = [triangle[i].z for i in (1, 2, 3)]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))


def boxes_touch(a, b, margin):
    return not (
        a[1] + margin < b[0] or b[1] + margin < a[0]
        or a[3] + margin < b[2] or b[3] + margin < a[2]
        or a[5] + margin < b[4] or b[5] + margin < a[4]
    )


def audit():
    triangles = collect_triangles()
    buckets = defaultdict(list)
    for index, t in enumerate(triangles):
        n = t[4]
        key = (round(n.x, 2) + 0.0, round(n.y, 2) + 0.0, round(n.z, 2) + 0.0, round(n.dot(t[1]) / 0.1))
        buckets[key].append(index)
    box = [bounds(t) for t in triangles]
    findings = defaultdict(lambda: {"count": 0, "area": 0.0, "where": None, "gap": 0.0})

    def compare(first, second, same_bucket):
        for i in first:
            for j in second:
                if same_bucket and j <= i:
                    continue
                a, b = triangles[i], triangles[j]
                if a[0] == b[0]:
                    continue
                if a[4].dot(b[4]) < SAME_DIRECTION:
                    continue
                gap = abs(a[4].dot(a[1]) - b[4].dot(b[1]))
                if gap > NEAR_TOL or not boxes_touch(box[i], box[j], NEAR_TOL):
                    continue
                area = overlap_area(a, b)
                if area < MIN_AREA:
                    continue
                kind = "FIGHT" if gap < PLANE_TOL else "NEAR"
                names = tuple(sorted((a[0], b[0])))
                record = findings[(kind,) + names]
                record["count"] += 1
                record["area"] += area
                record["gap"] = max(record["gap"], gap)
                if record["where"] is None:
                    center = (a[1] + a[2] + a[3]) / 3
                    record["where"] = [round(center.x, 1), round(center.y, 1), round(center.z, 1)]

    for key, members in buckets.items():
        compare(members, members, True)
        neighbor = (key[0], key[1], key[2], key[3] + 1)
        if neighbor in buckets:
            compare(members, buckets[neighbor], False)

    rows = []
    for key, record in findings.items():
        rows.append({
            "kind": key[0],
            "a": key[1],
            "b": key[2],
            "faces": record["count"],
            "area": round(record["area"], 1),
            "gap": round(record["gap"], 3),
            "at": record["where"],
        })
    rows.sort(key=lambda row: (row["kind"] != "FIGHT", -row["area"]))
    return {
        "file": bpy.data.filepath,
        "meshObjects": sum(1 for o in bpy.data.objects if o.type == "MESH" and not MARKER.match(o.name)),
        "triangles": len(triangles),
        "fightPairs": sum(1 for r in rows if r["kind"] == "FIGHT"),
        "nearPairs": sum(1 for r in rows if r["kind"] == "NEAR"),
        "top": rows[:14],
    }


if not globals().get("AUDIT_NO_RUN"):
    result = audit()
