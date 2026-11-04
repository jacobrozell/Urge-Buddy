#!/usr/bin/env bash
# Generate all iOS AppIcon sizes from a 1024x1024 master PNG.
# Usage: ./Scripts/generate-app-icons.sh <source-1024.png> <output-dir>

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <source-1024.png> <output-dir>" >&2
  exit 1
fi

SOURCE="$1"
OUT_DIR="$2"

if [[ ! -f "$SOURCE" ]]; then
  echo "Source not found: $SOURCE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

declare -a SPECS=(
  "40:icon-20@2x.png"
  "60:icon-20@3x.png"
  "58:icon-29@2x.png"
  "87:icon-29@3x.png"
  "76:icon-38@2x.png"
  "114:icon-38@3x.png"
  "80:icon-40@2x.png"
  "120:icon-40@3x.png"
  "120:icon-60@2x.png"
  "180:icon-60@3x.png"
  "128:icon-64@2x.png"
  "192:icon-64@3x.png"
  "136:icon-68@2x.png"
  "152:icon-76@2x.png"
  "167:icon-83_5@2x.png"
  "1024:ios-marketing.png"
)

for spec in "${SPECS[@]}"; do
  size="${spec%%:*}"
  name="${spec##*:}"
  sips -z "$size" "$size" "$SOURCE" --out "$OUT_DIR/$name" >/dev/null
  echo "Wrote $OUT_DIR/$name (${size}x${size})"
done

echo "Done. Icons are in place; rebuild to see them."
