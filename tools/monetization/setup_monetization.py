import argparse
import json
import mimetypes
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONFIG = os.path.join(ROOT, "src", "shared", "Monetization.lua")
ICONS = os.path.join(ROOT, "docs", "store", "icons")
UNIVERSE_ID = 10770936985

PASS_ICONS = {
    "double_income": "pass_double_income",
    "patron": "pass_patron",
    "rapid_growth": "pass_rapid_growth",
    "helping_hands": "pass_helping_hands",
    "swift_delivery": "pass_swift_delivery",
    "quick_merge": "pass_quick_merge",
    "premium_wardrobe": "pass_golden_wardrobe",
    "pet_lover": "pass_pet_lover",
}

PRODUCT_ICONS = {
    "bundle_s": "product_basket_s",
    "bundle_m": "product_basket_m",
    "bundle_l": "product_basket_l",
    "growth_lamp": "product_growth_lamp",
    "festival_boost": "product_festival_boost",
    "complete_s": "product_complete_now",
    "complete_m": "product_complete_now",
    "complete_l": "product_complete_now",
    "order_rare": "product_special_order",
    "order_epic": "product_special_order",
    "order_legendary": "product_special_order",
    "legacy_boost": "product_legacy_boost",
    "pet_pick_1": "product_special_pet",
    "pet_pick_2": "product_special_pet",
    "pet_pick_3": "product_special_pet",
    "starter_pack": "product_starter_pack",
    "cosmetic_49": "product_cosmetic",
    "cosmetic_99": "product_cosmetic",
    "cosmetic_149": "product_cosmetic",
    "cosmetic_249": "product_cosmetic",
    "cosmetic_399": "product_cosmetic",
    "cosmetic_799": "product_cosmetic",
}

LINE = re.compile(r'^\t\{ key = "(?P<key>[^"]+)", id = (?P<id>\d+), robux = (?P<robux>\d+),(?P<rest>.*)\},$')
NAME = re.compile(r'name = "(?P<name>[^"]*)"')
BLURB = re.compile(r'blurb = "(?P<blurb>[^"]*)"')


def parse():
    with open(CONFIG, "r", encoding="utf-8") as handle:
        lines = handle.read().split("\n")
    entries = []
    section = None
    for index, line in enumerate(lines):
        if line.startswith("Monetization.passes"):
            section = "pass"
        elif line.startswith("Monetization.products"):
            section = "product"
        match = LINE.match(line)
        if match and section:
            rest = match.group("rest")
            name = NAME.search(rest)
            blurb = BLURB.search(rest)
            entries.append({
                "kind": section,
                "key": match.group("key"),
                "id": int(match.group("id")),
                "robux": int(match.group("robux")),
                "name": name.group("name") if name else match.group("key"),
                "blurb": blurb.group("blurb") if blurb else "",
                "line": index,
            })
    return lines, entries


def multipart(fields, files):
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" % (boundary, name, value)).encode("utf-8"))
    for name, (filename, data) in files.items():
        kind = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        head = "--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: %s\r\n\r\n" % (boundary, name, filename, kind)
        parts.append(head.encode("utf-8") + data + b"\r\n")
    parts.append(("--%s--\r\n" % boundary).encode("utf-8"))
    return b"".join(parts), "multipart/form-data; boundary=%s" % boundary


def create(entry, key, universe):
    if entry["kind"] == "pass":
        url = "https://apis.roblox.com/game-passes/v1/universes/%d/game-passes" % universe
        icon = PASS_ICONS.get(entry["key"])
        id_field = "gamePassId"
    else:
        url = "https://apis.roblox.com/developer-products/v2/universes/%d/developer-products" % universe
        icon = PRODUCT_ICONS.get(entry["key"])
        id_field = "productId"
    fields = {
        "name": entry["name"],
        "description": entry["blurb"],
        "isForSale": "true",
        "price": str(entry["robux"]),
        "isRegionalPricingEnabled": "true",
    }
    files = {}
    if icon:
        path = os.path.join(ICONS, icon + ".png")
        if os.path.exists(path):
            with open(path, "rb") as handle:
                files["imageFile"] = (icon + ".png", handle.read())
    body, content_type = multipart(fields, files)
    request = urllib.request.Request(url, data=body, method="POST", headers={"x-api-key": key, "Content-Type": content_type})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise RuntimeError("HTTP %d: %s" % (error.code, error.read().decode("utf-8", "replace")[:400]))
    value = payload.get(id_field)
    if not value:
        raise RuntimeError("no id in response: %s" % json.dumps(payload)[:300])
    return int(value)


def main():
    parser = argparse.ArgumentParser(description="Create the Grow a Synagogue game passes and developer products and write their ids into Monetization.lua")
    parser.add_argument("--dry-run", action="store_true", help="list what would be created without calling Roblox")
    parser.add_argument("--universe", type=int, default=UNIVERSE_ID)
    args = parser.parse_args()
    key = os.environ.get("ROBLOX_API_KEY", "")
    lines, entries = parse()
    pending = [entry for entry in entries if entry["id"] == 0]
    print("%d passes and products in the config, %d still need an id" % (len(entries), len(pending)))
    for entry in pending:
        print("  %-8s %-18s R$ %-4d %s" % (entry["kind"], entry["key"], entry["robux"], entry["name"]))
    if args.dry_run or not pending:
        return 0
    if not key:
        print("Set ROBLOX_API_KEY first (see docs/MONETIZATION_SETUP.md).")
        return 1
    failures = 0
    for entry in pending:
        try:
            asset_id = create(entry, key, args.universe)
        except Exception as error:
            failures += 1
            print("FAILED %s: %s" % (entry["key"], error))
            time.sleep(1.0)
            continue
        line = lines[entry["line"]]
        lines[entry["line"]] = line.replace("id = 0,", "id = %d," % asset_id, 1)
        print("created %-18s id %d" % (entry["key"], asset_id))
        with open(CONFIG, "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines))
        time.sleep(0.7)
    print("done, %d failed" % failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
