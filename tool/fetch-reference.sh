#!/usr/bin/env bash
# Fetch the reference material described in REFERENCE.md.
#
# Everything here is outside the repository on purpose: it is material to port from and to test
# against, not the product. Every clone is pinned to a commit, so a port written today still
# matches its source tomorrow, and the licence of each one is recorded in REFERENCE.md.
#
# The pins themselves live in tool/reference-pins.tsv (dir, url, commit, licence, what it is
# for), one line per source named in docs/SOURCES.md. Adding a source means adding a line
# there and a row in REFERENCE.md, in the same PR that uses it.
#
#   tool/fetch-reference.sh              # code sources (default)
#   tool/fetch-reference.sh --assets     # also the image-heavy asset repos, un-checked-out
#   tool/fetch-reference.sh --check      # only report what is present and at which commit
set -euo pipefail

REF="${PUZZLESTACK_REFERENCE:-$HOME/Projects/puzzlestack-reference}"
PINS="$(cd "$(dirname "$0")" && pwd)/reference-pins.tsv"
MODE="${1:-}"
mkdir -p "$REF"

fail=0
while IFS=$'\t' read -r dir url commit licence purpose; do
  [ -z "$dir" ] && continue
  # The four image-heavy sources are pinned but not checked out: they are art, fetched one file
  # at a time when a picture nonogram is built, and cloning them whole costs gigabytes.
  assets=0
  case "$purpose" in *"assets: --no-checkout"*) assets=1 ;; esac

  if [ "$MODE" = "--check" ]; then
    if [ -d "$REF/$dir/.git" ]; then
      now=$(git -C "$REF/$dir" rev-parse HEAD 2>/dev/null || echo none)
      [ "$now" = "$commit" ] && mark=ok || mark="OFF PIN"
      printf '%-42s %s %s\n' "$dir" "${now:0:10}" "$mark"
    else
      printf '%-42s missing\n' "$dir"
    fi
    continue
  fi

  if [ "$assets" = 1 ] && [ "$MODE" != "--assets" ]; then
    continue
  fi

  if [ ! -d "$REF/$dir/.git" ]; then
    if [ "$assets" = 1 ]; then
      # No checkout: the tree is present and pinned, the blobs come on demand.
      git clone -q --depth 1 --filter=blob:none --no-checkout "$url" "$REF/$dir"
    else
      git clone -q --depth 1 "$url" "$REF/$dir"
    fi
  fi
  if ! git -C "$REF/$dir" cat-file -e "$commit^{commit}" 2>/dev/null; then
    # A shallow clone of the default branch may not contain an older pin.
    git -C "$REF/$dir" fetch -q --depth 1 origin "$commit" || true
  fi
  if git -C "$REF/$dir" checkout -q "$commit" 2>/dev/null; then
    printf '%-42s %s  %-24s %s\n' "$dir" "${commit:0:10}" "$licence" "$purpose"
  else
    printf '%-42s CANNOT CHECK OUT %s\n' "$dir" "${commit:0:10}"
    fail=1
  fi
done < "$PINS"

if [ "$MODE" = "--check" ]; then
  exit 0
fi

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

exit "$fail"
