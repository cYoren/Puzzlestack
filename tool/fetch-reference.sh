#!/usr/bin/env bash
# Fetch the reference material described in REFERENCE.md.
#
# Only Tatham's collection is fetchable: it is MIT and public. The invariant archive is a
# private zip with no upstream, so this script can only tell you where it should be.
set -euo pipefail

REF="${PUZZLESTACK_REFERENCE:-$HOME/Projects/puzzlestack-reference}"
TATHAM_REPO="https://git.tartarus.org/simon/puzzles.git"
# Pinned so a port written today still matches the source tomorrow.
TATHAM_COMMIT="616da16f25da428ccda805536209095bd062676e"

mkdir -p "$REF"

if [ -d "$REF/tatham-c/.git" ]; then
  echo "tatham-c already present at $REF/tatham-c"
  git -C "$REF/tatham-c" fetch -q origin
else
  echo "cloning Tatham's collection into $REF/tatham-c"
  git clone -q "$TATHAM_REPO" "$REF/tatham-c"
fi

git -C "$REF/tatham-c" checkout -q "$TATHAM_COMMIT"
echo "tatham-c at $(git -C "$REF/tatham-c" rev-parse --short HEAD) ($(ls "$REF/tatham-c"/*.c | wc -l) .c files)"

if [ -d "$REF/invariant" ]; then
  echo "invariant present at $REF/invariant ($(ls "$REF/invariant/INVARIANT/puzzles" | wc -l) puzzles)"
else
  cat <<'EOF'

invariant is MISSING and cannot be fetched: it arrived as a private zip and has no
upstream. Restore invariant-main.zip into

    $REF/invariant-main.zip

and extract it to $REF/invariant. Read-only reference, no licence declared: see
REFERENCE.md before copying anything from it.
EOF
fi
