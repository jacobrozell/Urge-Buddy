# Urge Buddy 1.0.0 — release todo

One list for the first App Store submit. Details live in the linked docs.

Status legend: `[ ]` todo · `[x]` done

| | |
|--|--|
| **Version** | `1.0.0` (build 9 in `project.yml`, not archived) |
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
- [x] Push `main` and archive build 9. Xcode Cloud Release run 8 (`62072743-4553-46a3-942e-54a6577e37ad`).
- [x] Recapture and upload the iPhone 6.9" and iPad 13" sets (2026-11-04). Duo still needs a Device Hub pose control — [`app-store-copy.md`](app-store-copy.md#iphone-duo-badge)
- [x] Tests for legacy backup fixtures and crisis resources.
- [ ] Optional: Accessibility, Architecture, and Code smells lanes — [Pending lanes](../../ongoing/1.0.0-review-fixes.md#pending-lanes)

## Jacob, manual in App Store Connect

- [ ] Age-rating questionnaire. Answers are in [Age rating notes](app-store-copy.md#age-rating-notes). Record the result there.
- [ ] App Privacy is **Data Not Collected** — [code-health 1.2](../../ongoing/code-health-plan.md)
- [ ] Paste the updated description (reminder bullet, #14) — [`app-store-copy.md`](app-store-copy.md#description)
- [x] iPhone 6.9" and iPad 13" screenshots replaced from build 8 (2026-11-02)
- [ ] Upload the recaptured iPhone 6.9", iPad 13", and Duo (outer and inner) sets
- [ ] Confirm review notes match [Review notes](app-store-copy.md#review-notes)
- [ ] Select build 9 for version 1.0

## Device QA

- [ ] Open rows in [`device-qa-matrix.md`](../device-qa-matrix.md): portrait screens not re-run, landscape and iPad spot checks, Stage Manager, Duo fold mid-flow, AX3, and dark mode
- [ ] Daily reminder and a milestone notice fire on a physical iPhone — [`feature-inventory.md`](../feature-inventory.md)
- [ ] Fresh TestFlight install on a physical iPhone: onboarding, check-in, urge, slip
- [ ] Backup export and import round-trip on a device
- [ ] VoiceOver and Reduce Motion on the core journey. Neither was run live — [ui-polish, found while working](../../ongoing/ui-polish-plan.md#found-while-working)
- [ ] 7-day dogfood on a physical iPhone, or a waiver — [archived checklist](../archive/2026-06-lean-1.0/release/1.0.0-ship-checklist.md#quality)

## Owner decisions

From [Decisions for the owner](../../ongoing/ui-polish-plan.md#decisions-for-the-owner). Each can be "keep as is".

- [ ] A. Tone down the dark-mode brand fill
- [x] B. Brand mark reads as "sync". The icon and `BrandMark` are now the teal two circles (2026-11-03).
- [ ] C. Drop the days from the run clock line
- [ ] D. Collapse the urge journal behind a button
- [x] E. Re-upload screenshots. iPhone 6.9" and iPad 13" uploaded 2026-11-04. Duo is still the earlier set.

## Submit

- [ ] Every item above is checked or waived
- [ ] Add for Review and submit version 1.0
- [ ] After approval: tag `1.0.0` on `main`, and update [`project-status.md`](../project-status.md) and [`feature-inventory.md`](../feature-inventory.md). What's New waits for the first update.
