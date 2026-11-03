# Urge Buddy 1.0.0 — release todo

One list for the first App Store submit. Details live in the linked docs.

Status legend: `[ ]` todo · `[x]` done

| | |
|--|--|
| **Version** | `1.0.0` (build 8 in `project.yml`) |
| **Branch** | `ui-polish` |
| **Archive** | Xcode Cloud `Release` workflow. Push the branch first, then run [`DaRules/scripts/trigger-xcode-cloud.sh`](../../../../DaRules/scripts/trigger-xcode-cloud.sh) `start UrgeBuddy <branch>`. The build runs on the remote branch. |
| **Status** | [`../project-status.md`](../project-status.md) |

**Last updated:** 2026-11-03

---

## Agent-doable

- [x] Review-lane fixes #1–#13 — [`1.0.0-review-fixes.md`](../../ongoing/1.0.0-review-fixes.md)
- [x] #14: onboarding reminder line and the listing description mention milestone notices — [#14](../../ongoing/1.0.0-review-fixes.md#14-reminder-copy-ignores-milestone-notices)
- [x] Save failures show an alert — [code-health 1.1](../../ongoing/code-health-plan.md)
- [x] Release dSYMs and zero warnings — [code-health 1.2](../../ongoing/code-health-plan.md)
- [x] Privacy manifest, and legal pages live — review-fixes #2 and #13
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO` in `project.yml`
- [x] Build 8 archived and in TestFlight (Xcode Cloud run 7)
- [ ] Commit #14, bump to build 9, push, and archive. Build 8 still has the old onboarding line.
- [ ] Recapture the iPhone Duo set from the current build (`Scripts/capture-duo-marketing-screenshots.sh`). The Connect set is the earlier capture — [`app-store-copy.md`](app-store-copy.md#iphone-duo-badge)
- [ ] Optional: Accessibility, Architecture, and Code smells lanes, plus tests for legacy backup fixtures and crisis resources — [Pending lanes](../../ongoing/1.0.0-review-fixes.md#pending-lanes)

## Jacob, manual in App Store Connect

- [ ] Age-rating questionnaire. Answers are in [Age rating notes](app-store-copy.md#age-rating-notes). Record the result there.
- [ ] App Privacy is **Data Not Collected** — [code-health 1.2](../../ongoing/code-health-plan.md)
- [ ] Paste the updated description (reminder bullet, #14) — [`app-store-copy.md`](app-store-copy.md#description)
- [x] iPhone 6.9" and iPad 13" screenshots replaced from build 8 (2026-11-02)
- [ ] Upload the recaptured iPhone Duo set (outer and inner)
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
- [ ] B. Brand mark reads as "sync"
- [ ] C. Drop the days from the run clock line
- [ ] D. Collapse the urge journal behind a button
- [ ] E. Re-upload screenshots. iPhone and iPad are done. Duo is open.

## Submit

- [ ] Every item above is checked or waived
- [ ] Add for Review and submit version 1.0
- [ ] After approval: merge `ui-polish` to `main`, tag `1.0.0`, and update [`project-status.md`](../project-status.md) and [`feature-inventory.md`](../feature-inventory.md). What's New waits for the first update.
