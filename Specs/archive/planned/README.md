# Post-1.0 Specifications

Specs in this folder are **not** in scope for lean 1.0.0. Do not implement or expose in Release builds until promoted to `specs/` root and updated in [`docs/feature-inventory.md`](../../docs/feature-inventory.md).

---

## Planned features

| Spec | Target release | Legacy draft |
|------|----------------|--------------|
| [`CompetitiveFeaturesSpec.md`](CompetitiveFeaturesSpec.md) | 1.1–1.2 | [`docs/product/competitive-strategy.md`](../../docs/product/competitive-strategy.md) |
| [`WidgetSpec.md`](WidgetSpec.md) | 1.2 (phased) | 8 focused widgets + snapshot schema; `TODOs/todo_widget.md`, `TrackBoth-Widget/` |
| [`LiveActivitySpec.md`](LiveActivitySpec.md) | 1.1 | — |
| [`AppleWatchSpec.md`](AppleWatchSpec.md) | 1.2 | `Specs/apple-watch-spec.md`, `Views/WatchViews/` |
| [`MotivationGameSpec.md`](MotivationGameSpec.md) | TBD | `Specs/motivation-game-spec.md` |
| [`NotificationsSpec.md`](NotificationsSpec.md) | 1.2 | `TODOs/TODO.md` |
| [`ShortcutsSpec.md`](ShortcutsSpec.md) | 1.2 | — |
| [`AchievementsSpec.md`](AchievementsSpec.md) | 1.3 | — |

## Platform ports (research only)

| Spec | Notes |
|------|-------|
| [`AndroidPortSpec.md`](AndroidPortSpec.md) | `Specs/android-porting-spec.md` |
| [`ReactNativePortSpec.md`](ReactNativePortSpec.md) | `Specs/react-native-porting-spec.md` |

---

## Promotion workflow

1. Feature approved for a release → move spec from `planned/` to `specs/` root (or create new authoritative spec).
2. Update `docs/feature-inventory.md` status.
3. Update `ProductSurfaceSpec.md` matrix.
4. Add Verification block with target semver.
5. Do not edit legacy `Specs/` files — link from new spec if needed.
