# Contributing to Urge Buddy

## Project generation

The Xcode project is generated from `UrgeBuddy/project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen). **Do not hand-edit** `UrgeBuddy.xcodeproj`. Change `project.yml` or source folders, then regenerate:

```bash
cd UrgeBuddy
brew install xcodegen   # once
xcodegen generate
open UrgeBuddy.xcodeproj
```

## Schemes

| Scheme | Purpose |
|--------|---------|
| `UrgeBuddy` | Local dev — run the app and unit + UI tests |
| `UrgeBuddyCI` | CI — builds the app and both test targets |
| `UrgeBuddyScreenshots` | App Store screenshots — `-skip_onboarding -seed_demo -ui_testing` |

## Running tests locally

```bash
cd UrgeBuddy

xcodebuild test \
  -project UrgeBuddy.xcodeproj \
  -scheme UrgeBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:UrgeBuddyTests \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -project UrgeBuddy.xcodeproj \
  -scheme UrgeBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:UrgeBuddyUITests \
  CODE_SIGNING_ALLOWED=NO
```

Coverage gate (after a unit test run with `-enableCodeCoverage YES`):

```bash
../Scripts/check-coverage.sh /path/to/UrgeBuddyTestResults.xcresult 50
```

## Conventions

See [`Specs/README.md`](Specs/README.md) and [`docs/project-status.md`](docs/project-status.md). Bundle ID and URL scheme stay `com.jacobrozell.TrackBoth` / `trackboth` for App Store Connect; the Swift module is `UrgeBuddy`.
