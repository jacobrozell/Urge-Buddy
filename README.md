# Urge Buddy

Quit vices. Build habits.

Urge Buddy helps you quit what's hurting you and build what helps: a 10-second daily check-in, a tool for riding out urges, and progress a slip can't erase.

## Tabs

| Tab | What it's for |
|-----|----------------|
| **Today** | Check in, see days free, tick helper habits, open "I'm having an urge" |
| **Progress** | Saved, urges beaten, journal, and a calendar per metric |
| **Settings** | Reminders, app lock, backup, and get help now |

Universal iPhone and iPad app with portrait and landscape. Layout adapts via size classes (see `Specs/DesignSystemSpec.md` §8.7).

## Build and test

From `UrgeBuddy/` (the folder that contains `project.yml`):

```bash
xcodegen generate
```

```bash
xcodebuild build -project UrgeBuddy.xcodeproj -scheme UrgeBuddyCI -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

```bash
xcodebuild test -project UrgeBuddy.xcodeproj -scheme UrgeBuddy -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:UrgeBuddyTests CODE_SIGNING_ALLOWED=NO
```

```bash
xcodebuild test -project UrgeBuddy.xcodeproj -scheme UrgeBuddy -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:UrgeBuddyUITests CODE_SIGNING_ALLOWED=NO
```

Requires Xcode 26. Do not hand-edit `UrgeBuddy.xcodeproj`.

## Layout

```
UrgeBuddy/UrgeBuddy/
├── App/            shell, router, lock gate
├── DesignSystem/   palette, type, components
├── Features/       Today, Check-in, Urge, Slip, Progress, Onboarding, Settings
├── Domain/         Foundation-only rules (inject now and calendar)
├── Data/           SwiftData models, RecoveryStore, backup
├── Services/       reminders, app lock, preferences
├── Support/        links, accessibility ids, debug surface
└── Resources/      assets, Info.plist, privacy manifest
```

## Repo

GitHub: [jacobrozell/Urge-Buddy](https://github.com/jacobrozell/Urge-Buddy)

The Xcode module is **UrgeBuddy**. App Store bundle ID remains `com.jacobrozell.TrackBoth` (unchanged Connect record).

## Docs

- [`docs/project-status.md`](docs/project-status.md) — current release focus
- [`Specs/ProductSpec.md`](Specs/ProductSpec.md) — product rules
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — agent and contributor conventions
