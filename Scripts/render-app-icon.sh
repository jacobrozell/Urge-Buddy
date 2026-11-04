#!/usr/bin/env bash
# Render the teal two-circle app icon as an opaque 1024x1024 master PNG (needs ImageMagick).
# Colors follow AppTheme.teal in UrgeBuddy/DesignSystem/Theme.swift; BrandMark draws the same shape.
# Usage: ./Scripts/render-app-icon.sh <out-1024.png>
#   then: ./Scripts/generate-app-icons.sh <out-1024.png> UrgeBuddy/Resources/Assets.xcassets/AppIcon.appiconset

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <out-1024.png>" >&2
  exit 1
fi

OUT="$1"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Drawn at 2x and downsampled for smooth edges. Circle radius 0.215 and offset 0.098 of the tile.
N=2048; R=440; CY=1024; AX=824; BX=1224

magick -size ${N}x${N} -define gradient:angle=135 gradient:'#13534E'-'#03201E' "$WORK/bg.png"
magick -size ${N}x${N} xc:black -fill white -draw "circle $AX,$CY $AX,$((CY-R))" "$WORK/maskA.png"
magick -size ${N}x${N} xc:black -fill white -draw "circle $BX,$CY $BX,$((CY-R))" "$WORK/maskB.png"
magick "$WORK/maskA.png" "$WORK/maskB.png" -compose multiply -composite "$WORK/maskAB.png"
magick -size ${N}x${N} gradient:'#5EEAD4'-'#0D9488' "$WORK/maskA.png" -alpha off -compose copy_opacity -composite "$WORK/a.png"
magick -size ${N}x${N} gradient:'#A7F3D0'-'#10B981' "$WORK/maskB.png" -alpha off -compose copy_opacity -composite "$WORK/b.png"
magick -size ${N}x${N} gradient:'#F0FDFA'-'#99F6E4' "$WORK/maskAB.png" -alpha off -compose copy_opacity -composite "$WORK/ab.png"
magick "$WORK/bg.png" "$WORK/a.png" -compose over -composite "$WORK/b.png" -compose over -composite \
  "$WORK/ab.png" -compose over -composite -resize 1024x1024 -alpha off -depth 8 -strip "$OUT"

echo "Wrote $OUT"
