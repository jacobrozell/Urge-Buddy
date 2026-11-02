# TrackBoth — future ideas

**Product/UX review & decisions:** [`ProductUXHandoff.md`](ProductUXHandoff.md) · **Release handoff:** [`ReviewerReadinessHandoff.md`](ReviewerReadinessHandoff.md)

Post-1.0 specs: [`../../Specs/planned/README.md`](../../Specs/planned/README.md) · Inventory: [`../feature-inventory.md`](../feature-inventory.md)

## Next up (from the 2026-11 product review)

Ordered by how much they help in the moment of need.

| Idea | Target | Notes |
|------|--------|-------|
| **App Intents: urge** | 1.1 | "I'm having an urge" as an App Intent: Siri, Shortcuts, Action button, and a Control Center control. Opens the urge flow on the chosen vice. |
| **App Intents: log and check in** | 1.1 | "Log one cigarette", "Mark today free", "Did I drink water?" Intents that write through `RecoveryStore` without opening the app. Cut-back +1 and amount-habit +1 are the most used. |
| **Urge-first widgets** | 1.1 | Lock-screen urge button (opens `trackboth://urge`), days-free widget, cut-back "3 of 8 today" with an interactive +1 (iOS 17 `Button(intent:)`). Respect discreet mode. |
| **Notification check-in buttons** | 1.1 | Actions on the daily reminder: "Free today" for quit vices, "Log amount" for cut backs. One reminder a day still. |
| **Neutral app icon** | 1.1 | Alternate icon that doesn't look like a recovery app. Pairs with discreet notifications and app lock. |
| **Multi-day catch-up** | 1.1 | When check-in was missed for a few days, one sheet to confirm each missed day instead of opening the calendar. |
| **Urge-strength trend** | 1.2 | "Your urges are getting weaker": average strength by week on the detail screen. Data already exists on `UrgeEvent.intensity`. |
| **Mood ↔ slip patterns** | 1.2 | Use day mood with slips and urges: "Slips happen more on Low days." Needs ~3 weeks of data before showing. |
| **Replacement habit link** | 1.2 | Link a habit to a vice ("walk instead of smoke"). Urge flow suggests it first; detail shows how often it was used during urges. |
| **Weekly goals** | 1.2 | Weekly targets for habits ("gym 3× a week") and weekly limits for cut backs. Daily targets and limits shipped first. |
| **Apple Watch** | 1.2 | Urge button, breathing timer, +1 for cut backs. Archived views → planned port. |
| **SwiftData + iCloud** | TBD | [`../plans/swiftdata-icloud-migration.md`](../plans/swiftdata-icloud-migration.md). Opt-in. Needs the V3 schema with all-optional fields. |
| **Positioning: free and private** | Listing | Lead the App Store copy with no account, no ads, no tracking, everything on device, quit or cut back. Most competitors paywall or require sign-up. |

## Earlier ideas

| Idea | Target | Notes |
|------|--------|-------|
| **Smart notifications** | 1.2 | [`NotificationsSpec.md`](../../Specs/planned/NotificationsSpec.md) |
| **Shortcuts / Siri** | 1.1 | Superseded by the App Intents rows above. [`ShortcutsSpec.md`](../../Specs/planned/ShortcutsSpec.md) |
| **Achievements / badges** | 1.3 | [`AchievementsSpec.md`](../../Specs/planned/AchievementsSpec.md) |
| **Competitive features** | 1.1–1.2 | [`CompetitiveFeaturesSpec.md`](../../Specs/planned/CompetitiveFeaturesSpec.md) |
