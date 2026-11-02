#!/usr/bin/env bash
# Reports UrgeBuddy core-logic line coverage from an xcodebuild xcresult bundle.
set -euo pipefail

RESULT_BUNDLE="${1:?Usage: check-coverage.sh <path-to.xcresult> [min-percent]}"
MIN_COVERAGE="${2:-50}"

if [[ ! -d "$RESULT_BUNDLE" ]]; then
  echo "Result bundle not found: $RESULT_BUNDLE" >&2
  exit 1
fi

COVERAGE_LINE=$(xcrun xccov view --report --json "$RESULT_BUNDLE" \
  | python3 -c '
import json, sys

CORE_FILES = {
    "DayMath.swift", "RecoveryMath.swift", "HabitMath.swift", "MilestonePolicy.swift",
    "TriggerTag.swift", "PatternInsights.swift", "RecoveryStore.swift", "Snapshots.swift",
    "BackupService.swift", "BackupV5.swift", "LegacyExportV4.swift", "MilestoneLedger.swift",
    "Preferences.swift", "BootstrapStoreRecovery.swift", "WCAGContrast.swift",
    "RecoveryCopy.swift", "ReminderScheduler.swift",
}

data = json.load(sys.stdin)
targets = data.get("targets", [])
app = next((t for t in targets if t.get("name", "").endswith("UrgeBuddy.app")), None)
if not app:
    print("0")
    sys.exit(0)

covered = 0
executable = 0
for file_info in app.get("files", []):
    if file_info.get("name") in CORE_FILES:
        covered += file_info.get("coveredLines", 0)
        executable += file_info.get("executableLines", 0)

if executable == 0:
    print("0")
else:
    print(f"{(covered / executable) * 100:.2f}")
')

echo "UrgeBuddy core-logic line coverage: ${COVERAGE_LINE}% (minimum ${MIN_COVERAGE}%)"

OVERALL_LINE=$(xcrun xccov view --report --json "$RESULT_BUNDLE" \
  | python3 -c '
import json, sys
data = json.load(sys.stdin)
app = next((t for t in data.get("targets", []) if t.get("name", "").endswith("UrgeBuddy.app")), None)
if not app:
    print("0")
else:
    line_cov = app.get("lineCoverage", 0) * 100
    print(f"{line_cov:.2f}")
')
echo "UrgeBuddy overall app line coverage: ${OVERALL_LINE}% (informational — UI-heavy; core logic is gated)"

python3 - "$COVERAGE_LINE" "$MIN_COVERAGE" <<'PY'
import sys
coverage = float(sys.argv[1])
minimum = float(sys.argv[2])
if coverage + 1e-9 < minimum:
    print(f"Core coverage {coverage:.2f}% is below required {minimum:.0f}%", file=sys.stderr)
    sys.exit(1)
print("Core coverage gate passed.")
PY
