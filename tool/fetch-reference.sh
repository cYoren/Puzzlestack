#!/usr/bin/env bash
# Fetch the reference material described in REFERENCE.md.
#
# Everything here is outside the repository on purpose: it is material to port from and to test
# against, not the product. Every clone is pinned to a commit, so a port written today still
# matches its source tomorrow, and the licence of each one is recorded in REFERENCE.md.
set -euo pipefail

REF="${PUZZLESTACK_REFERENCE:-$HOME/Projects/puzzlestack-reference}"
mkdir -p "$REF"

# fetch <dir> <url> <commit> <what to print afterwards>
fetch() {
  local dir="$1" url="$2" commit="$3" note="$4"
  if [ -d "$REF/$dir/.git" ]; then
    echo "$dir already present at $REF/$dir"
    git -C "$REF/$dir" fetch -q origin || true
  else
    echo "cloning $dir"
    git clone -q "$url" "$REF/$dir"
  fi
  git -C "$REF/$dir" checkout -q "$commit"
  echo "$dir at $(git -C "$REF/$dir" rev-parse --short HEAD)  ($note)"
}

# Tatham's Portable Puzzle Collection. MIT. The Logic room's base, and the source of the
# no-guess Mines generator.
fetch tatham-c https://git.tartarus.org/simon/puzzles.git \
  616da16f25da428ccda805536209095bd062676e "$(ls "$REF/tatham-c"/*.c 2>/dev/null | wc -l) .c files"

# The thirteen puzzles that never made it into the collection, on the same framework. MIT.
fetch puzzles-unreleased https://github.com/x-sheep/puzzles-unreleased.git \
  b09e5a752d6461fead2a8f9e2900ed3eea8e4019 "$(ls "$REF/puzzles-unreleased"/*.c 2>/dev/null | wc -l) .c files"

# SCOWL: English word lists in size tiers. Answer lists come from the small tiers, which is the
# fix for answers nobody has heard of. Permissive, with its own notice.
fetch wordlist https://github.com/en-wl/wordlist.git \
  1e5b7d3a72f47a71da5d28686c1dd4b397178485 "$(ls "$REF/wordlist/data" 2>/dev/null | wc -l) data files"

# A solver, generator and graded database of sliding-car boards for block_escape. MIT.
fetch rush https://github.com/fogleman/rush.git \
  3e3b8396891d1802b30cb3129ae31fdedb319480 "Rush board database"

# Generated Sokoban levels in three difficulty sets, so no authored level set is needed.
# Apache-2.0.
fetch boxoban https://github.com/google-deepmind/boxoban-levels.git \
  78011d8c86ad423bfb2e1005012393b4c3c24409 "$(du -sh "$REF/boxoban" 2>/dev/null | cut -f1) of levels"

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
