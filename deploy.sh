#!/usr/bin/env bash
# Sync the World Cup 2026 dashboard into the hatch.org Hugo blog's static dir.
# Source of truth = this repo's index.html; the blog repo gets a committed copy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/index.html"

# Override with WORLD_CUP_DEST if the blog lives elsewhere.
DEST_DIR="${WORLD_CUP_DEST:-$SCRIPT_DIR/../hatch-org/blog/static/world-cup}"
DEST="$DEST_DIR/index.html"

[ -f "$SRC" ] || { echo "error: $SRC not found"; exit 1; }
[ -d "$(dirname "$DEST_DIR")/.." ] || { echo "error: blog dir not found near $DEST_DIR — set WORLD_CUP_DEST"; exit 1; }

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "✓ Copied index.html → $DEST"

# Sync static assets (hero image, etc.) that index.html references relatively.
for asset in hero.jpg; do
  [ -f "$SCRIPT_DIR/$asset" ] && cp "$SCRIPT_DIR/$asset" "$DEST_DIR/$asset" && echo "✓ Copied $asset → $DEST_DIR/$asset"
done

SRC_REV="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"

if [ "${1:-}" = "--commit" ]; then
  BLOG_ROOT="$(git -C "$DEST_DIR" rev-parse --show-toplevel)"
  git -C "$BLOG_ROOT" add "$DEST_DIR"
  git -C "$BLOG_ROOT" commit -m "Update world-cup dashboard (src @ $SRC_REV)"
  echo "✓ Committed in $BLOG_ROOT — push to trigger Amplify deploy."
else
  echo "Next: commit blog/static/world-cup/index.html in the blog repo and push to deploy."
  echo "  (or re-run: ./deploy.sh --commit)"
fi
