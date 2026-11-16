#!/usr/bin/env bash
# Compile the in-page boards.
#
# Each `web/games/<slug>.dart` is a few dozen lines of glue around an engine the
# app already has, compiled to one small JavaScript bundle by `dart compile js`.
# Nothing here imports Flutter, so a board is tens of KB instead of the app's
# 9.7 MB of Dart plus 7.2 MB of canvaskit.
#
#   tool/web_build.sh          # every board
#   tool/web_build.sh sudoku   # one
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/docs/js"
mkdir -p "$OUT"
for source in "$ROOT"/web/games/*.dart; do
  name=$(basename "$source" .dart)
  if [ $# -gt 0 ] && [[ ! " $* " == *" $name "* ]]; then continue; fi
  printf '%-12s ' "$name"
  dart compile js -O2 "$source" -o "$OUT/$name.js" 2>&1 |
    grep -E "Compiled|Error" | tail -1
  printf '%-12s %s\n' "" "$(du -h "$OUT/$name.js" | cut -f1)"
done
