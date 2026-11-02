#!/usr/bin/env bash
# Capture App Store Connect iPhone Duo screenshots (outer + inner).
#
# Native sizes match Connect:
#   Outer (folded):  1398×2034 portrait
#   Inner (open):    2853×2007 landscape (Device Hub Open pose)
#
# Uploading these is what puts the iPhone Duo badge on the product page.
#
# Usage:
#   ./Scripts/capture-duo-marketing-screenshots.sh
#   APPEARANCE=dark DISPLAYS=outer ./Scripts/capture-duo-marketing-screenshots.sh
#
# Requires Device Hub with the iPhone Duo simulator visible (pose buttons at the bottom).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/UrgeBuddy"
SIM_NAME="${SIM_NAME:-iPhone Duo}"
APPEARANCE="${APPEARANCE:-light}"
DISPLAYS="${DISPLAYS:-outer inner}"
BUNDLE_ID="com.jacobrozell.TrackBoth"
SCHEME="${SCHEME:-UrgeBuddy}"
PROJECT="$APP_DIR/UrgeBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/marketing-screenshots}"
LAUNCH_DELAY="${LAUNCH_DELAY:-8}"
POSE_SETTLE_SEC="${POSE_SETTLE_SEC:-2.5}"
MARKETING_BASE="${MARKETING_BASE:-$ROOT/marketing-screenshots}"
BASE_ARGS=(-skip_onboarding -ui_testing)
MARKETING_ARGS=("${BASE_ARGS[@]}" -seed_marketing)
CUTBACK_ARGS=("${BASE_ARGS[@]}" -seed_cutback)

OUTER_W=1398
OUTER_H=2034
INNER_W=2007
INNER_H=2853

echo "→ Project: $APP_DIR"
echo "→ Simulator: $SIM_NAME ($APPEARANCE)"
echo "→ Displays: $DISPLAYS"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$APP_DIR" && xcodegen generate)
fi

SIM_UDID="$(xcrun simctl list devices available -j | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('name') == name and d.get('isAvailable', True):
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" "$SIM_NAME")"
export SIM_UDID

echo "→ Booting $SIM_NAME ($SIM_UDID)…"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b
open -a DeviceHub 2>/dev/null || open -a "Device Hub" 2>/dev/null || true
xcrun simctl ui "$SIM_UDID" appearance "$APPEARANCE"

set_pose() {
  local pose="$1"
  echo "→ Device Hub pose: $pose"
  swift "$SCRIPT_DIR/devicehub-pose.swift" "$pose"
  sleep "$POSE_SETTLE_SEC"
}

flatten_png() {
  local path="$1"
  if command -v magick >/dev/null 2>&1; then
    local tmp="${path}.flat.png"
    magick "$path" -alpha off PNG24:"$tmp"
    mv "$tmp" "$path"
  fi
}

verify_size() {
  local path="$1"
  local expect_w="$2"
  local expect_h="$3"
  local w h
  if command -v magick >/dev/null 2>&1; then
    w="$(magick identify -format "%w" "$path")"
    h="$(magick identify -format "%h" "$path")"
  else
    w="$(sips -g pixelWidth "$path" | awk '/pixelWidth/ {print $2}')"
    h="$(sips -g pixelHeight "$path" | awk '/pixelHeight/ {print $2}')"
  fi
  if [[ "$w" != "$expect_w" || "$h" != "$expect_h" ]]; then
    echo "Screenshot $(basename "$path") is ${w}×${h}, expected ${expect_w}×${expect_h}." >&2
    return 1
  fi
}

# The ride clock changes every second. Shoot a quarter-second after a tick so the digits are still.
wait_for_settled_second() {
  python3 - <<'PY'
import time
frac = time.time() % 1.0
wait = 0.25 - frac if frac < 0.25 else (1.0 - frac) + 0.25
time.sleep(wait)
PY
}

capture_one() {
  local display="$1"
  local slug="$2"
  shift 2
  local -a args=("$@")
  local out_dir display_flag expect_w expect_h orientation
  if [[ "$display" == "outer" ]]; then
    display_flag="primary"
    expect_w="$OUTER_W"
    expect_h="$OUTER_H"
    orientation="portrait"
    out_dir="$MARKETING_BASE/iphone-duo/outer/$APPEARANCE/portrait"
  else
    display_flag="primary-1"
    expect_w="$INNER_H"
    expect_h="$INNER_W"
    orientation="landscape"
    out_dir="$MARKETING_BASE/iphone-duo/inner/$APPEARANCE/landscape"
  fi
  mkdir -p "$out_dir"
  local filename="iphone-duo-${display}-${slug}.png"
  echo "→ Capturing $display/$APPEARANCE/$orientation/${filename}…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.4
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${args[@]}" -snapshot_orientation "$orientation" >/dev/null
  sleep "$LAUNCH_DELAY"
  if printf '%s\n' "${args[@]}" | grep -qx -- '-urge_ride'; then
    wait_for_settled_second
  fi
  local out="$out_dir/$filename"
  xcrun simctl io "$SIM_UDID" screenshot --display="$display_flag" --mask=ignored "$out"
  flatten_png "$out"
  verify_size "$out" "$expect_w" "$expect_h"
}

capture_set() {
  local display="$1"
  capture_one "$display" "01-today" \
    "${MARKETING_ARGS[@]}"
  capture_one "$display" "02-urge-ride" \
    "${MARKETING_ARGS[@]}" -urge_ride
  capture_one "$display" "03-slip-summary" \
    "${MARKETING_ARGS[@]}" -slip_summary
  capture_one "$display" "04-progress-detail" \
    "${MARKETING_ARGS[@]}" -tab_progress -open_first_detail
  capture_one "$display" "05-cut-back" \
    "${CUTBACK_ARGS[@]}"
}

echo "→ Building app…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  | xcbeautify --quieter 2>/dev/null || xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/UrgeBuddy.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app not found at $APP_PATH" >&2
  exit 1
fi

echo "→ Installing app…"
xcrun simctl install "$SIM_UDID" "$APP_PATH"

for display in $DISPLAYS; do
  case "$display" in
    outer)
      set_pose closed
      capture_set outer
      ;;
    inner)
      set_pose open
      capture_set inner
      ;;
    *)
      echo "Unknown display: $display (use outer and/or inner)" >&2
      exit 1
      ;;
  esac
done

echo ""
echo "Done. Duo screenshots:"
find "$MARKETING_BASE/iphone-duo" -name '*.png' | sort
echo ""
echo "Upload outer PNGs to Connect → iPhone Duo (outer display) 1398×2034 portrait"
echo "Upload inner PNGs to Connect → iPhone Duo (inner display) 2853×2007 landscape (Open pose)"
