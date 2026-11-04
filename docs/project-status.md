# Urge Buddy — Project status

> Last updated: 2026-11-04

## At a glance

| Field | Value |
|-------|-------|
| **App Store name** | Urge Buddy |
| **Subtitle** | Quit vices. Build habits. |
| **Stage** | **Release prep** — version 1.0.0 ready to submit, not submitted |
| **Latest submitted** | — |
| **Latest shipped (App Store)** | — |
| **Repo version** | 1.0.0 (11). Connect still has build 10 selected until 11 finishes processing |
| **Active branch** | `main` |
| **Platform** | iOS 18+ — iPhone and iPad, portrait and landscape |
| **Monetization** | Free, no IAP |

## Current focus

**Version 1.0.0 is Prepare for Submission.** Build 11 is the archive that includes the pre-submit polish: tab-bar clearance, the darker dark-mode brand, the run clock line, and the collapsed urge journal. Build 10 stays selected until 11 is processed. Age rating is 13+. Copy, screenshots, review notes, and App Privacy (Data Not Collected) are done in Connect. The physical iPhone pass is done, and the 7-day dogfood is waived for this submit. What's New waits until the first release is live. Post-launch order is in `FutureIdeas/backlog.md` (App Intents first).

The app has never shipped. Build 5 was archived on 2026-06-22 and never uploaded. There is no production data to migrate.

## Release history

| Version | Build | Date | Channel | Notes |
|---------|-------|------|---------|-------|
| 1.0.0 | 5 | 2026-06-22 | Archive | Pre-overhaul Xcode archive. Not uploaded. |
| 1.0.0 | 6 | 2026-10-28 | Repo | Build number bumped for the overhaul. Not archived. |
| 1.0.0 | 7 | 2026-11-02 | TestFlight | Xcode Cloud run 6. Not submitted. |
| 1.0.0 | 8 | 2026-11-02 | TestFlight | Xcode Cloud run 7 (`e4de4fd6-f3ec-483f-9d20-19bc3b9195b0`). Not submitted. |
| 1.0.0 | 9 | 2026-11-04 | Repo | Xcode Cloud run 8 archived this number, then the export uploaded it as build 8. Not in TestFlight as 9. |
| 1.0.0 | 10 | 2026-11-04 | TestFlight | Xcode Cloud run 10. Selected in Connect until build 11 is processed. |
| 1.0.0 | 11 | 2026-11-04 | Repo | Pre-submit polish. Archive in progress. |

## Key docs

| Doc | Purpose |
|-----|---------|
| [`ongoing/recovery-overhaul-plan.md`](../ongoing/recovery-overhaul-plan.md) | Approved plan and progress log |
| [`Specs/README.md`](../Specs/README.md) | Current behavior specs |
| [`docs/feature-inventory.md`](feature-inventory.md) | Cut list and planned features |
| [`docs/release/app-store-copy.md`](release/app-store-copy.md) | Listing copy (rewritten at the end of the overhaul) |
| [`docs/release/todo.md`](release/todo.md) | 1.0.0 ship checklist |
| [`DaRules/scripts/trigger-xcode-cloud.sh`](../../../DaRules/scripts/trigger-xcode-cloud.sh) | Starts the Xcode Cloud archive |
