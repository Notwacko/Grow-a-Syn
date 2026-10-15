#!/bin/sh
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
STAGE="${TMPDIR:-/tmp}/growasyn_studio_stage"
PORT="${1:-8765}"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$ROOT/src" "$STAGE/src"
find "$STAGE" -name ".gitkeep" -delete
(cd "$STAGE" && find src -type f | sort > manifest.txt && find src -type d | sort > dirs.txt)
cd "$STAGE" && exec python3 -m http.server "$PORT" --bind 127.0.0.1
