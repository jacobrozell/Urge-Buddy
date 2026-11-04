# Urge Buddy 1.0.0 — release todo

One list for the first App Store submit. Details live in the linked docs.

Status legend: `[ ]` todo · `[x]` done

| | |
|--|--|
| **Version** | `1.0.0` (build 11 in `project.yml`) |
| **Branch** | `main` |
| **Archive** | Xcode Cloud `Release` workflow. Push the branch first, then run [`DaRules/scripts/trigger-xcode-cloud.sh`](../../../../DaRules/scripts/trigger-xcode-cloud.sh) `start UrgeBuddy <branch>`. The build runs on the remote branch. |
| **Status** | [`../project-status.md`](../project-status.md) |

**Last updated:** 2026-11-04

---

## Agent-doable

- [x] Review-lane fixes #1–#13 — [`1.0.0-review-fixes.md`](../../ongoing/1.0.0-review-fixes.md)
- [x] #14: onboarding reminder line and the listing description mention milestone notices — [#14](../../ongoing/1.0.0-review-fixes.md#14-reminder-copy-ignores-milestone-notices)
- [x] Save failures show an alert — [code-health 1.1](../../ongoing/code-health-plan.md)
- [x] Release dSYMs and zero warnings — [code-health 1.2](../../ongoing/code-health-plan.md)
- [x] Privacy manifest, and legal pages live — review-fixes #2 and #13
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO` in `project.yml`
- [x] Build 8 archived and in TestFlight (Xcode Cloud run 7)
- [x] Commit #14 and bump to build 9. Build 8 still has the old onboarding line.
- [x] Push `main` and archive build 9. Xcode Cloud Release run 8 (`62072743-4553-46a3-942e-54a6577e37ad`) succeeded, then the App Store export rewrote the build number to 8. TestFlight still has build 8.
- [x] Archive again so TestFlight gets build 9, including the introduction review fixes. Xcode Cloud Release run 9 (`43171651-b3e4-49ff-ac98-47acc82ba01d`). Build 9 is in TestFlight.
- [x] Recapture and upload the iPhone 6.9", iPad 13", and Duo sets (2026-11-04). Duo inner is landscape 2853×2007 — [`app-store-copy.md`](app-store-copy.md#iphone-duo-badge)
- [x] Bump to build 10. Build 9 is already in TestFlight. Xcode Cloud Release run 10 (`7f57f399-0aa5-40c8-9aef-d8b7c64a03c6`).
- [x] Bump to build 11 for the pre-submit polish. Xcode Cloud Release run 11 (`598eda42-1913-46bd-bfdc-7032394dedd2`).
- [x] Tests for legacy backup fixtures and crisis resources.
- [ ] Optional: Accessibility, Architecture, and Code smells lanes — [Pending lanes](../../ongoing/1.0.0-review-fixes.md#pending-lanes)

## Jacob, manual in App Store Connect

- [x] Age-rating questionnaire. Result is **13+** — [Age rating notes](app-store-copy.md#age-rating-notes) (2026-11-04).
- [x] App Privacy is **Data Not Collected** — confirmed in App Store Connect (2026-11-04)
- [x] Paste the updated description (reminder bullet, #14) — [`app-store-copy.md`](app-store-copy.md#description) (2026-11-04)
- [x] iPhone 6.9" and iPad 13" screenshots replaced from build 8 (2026-11-02)
- [x] Upload the recaptured iPhone 6.9", iPad 13", and Duo (outer and inner) sets (2026-11-04)
- [x] Review notes match [Review notes](app-store-copy.md#review-notes) (confirmed in Connect, 2026-11-04)
- [x] Build 10 is selected for version 1.0. It is valid in App Store Connect. Build 9 is also in TestFlight.

## Device QA

- [x] Daily reminder and a milestone notice fire on a physical iPhone — Jacob (2026-11-04)
- [x] Fresh TestFlight install on a physical iPhone: onboarding, check-in, urge, slip — Jacob (2026-11-04)
- [x] Backup export and import round-trip on a device — Jacob (2026-11-04)
- [x] VoiceOver and Reduce Motion on the core journey — Jacob (2026-11-04)
- [x] 7-day dogfood waived for this submit. The physical install is done (2026-11-04)
- [ ] Simulator matrix still open in [`device-qa-matrix.md`](../device-qa-matrix.md): landscape and iPad spot checks, Stage Manager, Duo fold mid-flow, AX3, and dark mode

## Owner decisions

From [Decisions for the owner](../../ongoing/ui-polish-plan.md#decisions-for-the-owner). Each can be "keep as is".

- [x] A. Dark-mode brand fill is `#14B8A6` (2026-11-04). The mark stays the icon teal.
- [x] B. Brand mark reads as "sync". The icon and `BrandMark` are now the teal two circles (2026-11-03).
- [x] C. Run clock line drops the day count: "4h 12m into day 10" (2026-11-04)
- [x] D. Urge journal starts behind "Write it down" (2026-11-04)
- [x] E. Re-upload screenshots. iPhone 6.9", iPad 13", and iPhone Duo uploaded 2026-11-04.

## Submit

- [ ] Every item above is checked or waived
- [ ] Add for Review and submit version 1.0
- [ ] After approval: tag `1.0.0` on `main`, and update [`project-status.md`](../project-status.md) and [`feature-inventory.md`](../feature-inventory.md). What's New waits for the first update.
