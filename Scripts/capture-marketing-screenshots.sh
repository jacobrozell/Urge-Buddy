#!/usr/bin/env bash
# Capture App Store Connect screenshots (portrait, light).
#
# iPhone 6.9"  1320×2868   SIM_NAME="iPhone 17 Pro Max"
# iPad 13"     2064×2752   DEVICE_KIND=ipad SIM_NAME="iPad Pro 13-inch (M5)"
#
# Usage:
#   ./Scripts/capture-marketing-screenshots.sh
#   DEVICE_KIND=ipad SIM_NAME="iPad Pro 13-inch (M5)" EXPECT_W=2064 EXPECT_H=2752 \
#     ./Scripts/capture-marketing-screenshots.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/UrgeBuddy"
DEVICE_KIND="${DEVICE_KIND:-iphone}"
APPEARANCE="${APPEARANCE:-light}"
BUNDLE_ID="com.jacobrozell.TrackBoth"
SCHEME="${SCHEME:-UrgeBuddy}"
PROJECT="$APP_DIR/UrgeBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/marketing-screenshots}"
LAUNCH_DELAY="${LAUNCH_DELAY:-8}"
MARKETING_BASE="${MARKETING_BASE:-$ROOT/marketing-screenshots}"
APP_STORE_RESIZE="${APP_STORE_RESIZE:-1}"

if [[ "$DEVICE_KIND" == "ipad" ]]; then
  SIM_NAME="${SIM_NAME:-iPad Pro 13-inch (M5)}"
  EXPECT_W="${EXPECT_W:-2064}"
  EXPECT_H="${EXPECT_H:-2752}"
else
  SIM_NAME="${SIM_NAME:-iPhone 17 Pro Max}"
  EXPECT_W="${EXPECT_W:-1320}"
  EXPECT_H="${EXPECT_H:-2868}"
fi

BASE_ARGS=(-skip_onboarding -ui_testing)
MARKETING_ARGS=("${BASE_ARGS[@]}" -seed_marketing)
CUTBACK_ARGS=("${BASE_ARGS[@]}" -seed_cutback)

echo "→ Project: $APP_DIR"
echo "→ Simulator: $SIM_NAME ($APPEARANCE, portrait)"
echo "→ Target size: ${EXPECT_W}×${EXPECT_H}"

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
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" \
  || open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app --args -CurrentDeviceUDID "$SIM_UDID" \
  || true
xcrun simctl ui "$SIM_UDID" appearance "$APPEARANCE"

flatten_and_size() {
  local path="$1"
  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick is required. Install with: brew install imagemagick" >&2
    exit 1
  fi
  magick "$path" -alpha off -filter Lanczos -resize "${EXPECT_W}x${EXPECT_H}!" PNG24:"$path"
  local w h
  w="$(magick identify -format "%w" "$path")"
  h="$(magick identify -format "%h" "$path")"
  if [[ "$w" != "$EXPECT_W" || "$h" != "$EXPECT_H" ]]; then
    echo "Screenshot $(basename "$path") is ${w}×${h}, expected ${EXPECT_W}×${EXPECT_H}." >&2
    exit 1
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
  local slug="$1"
  shift
  local -a args=("$@")
  local out_dir="$MARKETING_BASE/$DEVICE_KIND/$APPEARANCE/portrait"
  mkdir -p "$out_dir"
  local filename="${DEVICE_KIND}-${slug}.png"
  echo "→ Capturing $DEVICE_KIND/$APPEARANCE/portrait/${filename}…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.4
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${args[@]}" -snapshot_orientation portrait >/dev/null
  sleep "$LAUNCH_DELAY"
  if printf '%s\n' "${args[@]}" | grep -qx -- '-urge_ride'; then
    wait_for_settled_second
  fi
  local out="$out_dir/$filename"
  xcrun simctl io "$SIM_UDID" screenshot --mask=ignored "$out"
  if [[ "$APP_STORE_RESIZE" == 1 ]]; then
    flatten_and_size "$out"
  fi
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

capture_one "01-today" "${MARKETING_ARGS[@]}"
capture_one "02-urge-ride" "${MARKETING_ARGS[@]}" -urge_ride
capture_one "03-slip-summary" "${MARKETING_ARGS[@]}" -slip_summary
capture_one "04-progress-detail" "${MARKETING_ARGS[@]}" -tab_progress -open_first_detail
capture_one "05-cut-back" "${CUTBACK_ARGS[@]}"

echo ""
echo "Done. Screenshots (${EXPECT_W}×${EXPECT_H}):"
find "$MARKETING_BASE/$DEVICE_KIND/$APPEARANCE/portrait" -name '*.png' | sort
