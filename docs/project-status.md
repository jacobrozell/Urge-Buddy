# Urge Buddy — Project status

> Last updated: 2026-11-04

## At a glance

| Field | Value |
|-------|-------|
| **App Store name** | Urge Buddy |
| **Subtitle** | Quit vices. Build habits. |
| **Stage** | **Release prep** — never shipped |
| **Latest submitted** | — |
| **Latest shipped (App Store)** | — |
| **Repo version** | 1.0.0 (9), Xcode Cloud run 9 |
| **Active branch** | `main` |
| **Platform** | iOS 18+ — iPhone and iPad, portrait and landscape |
| **Monetization** | Free, no IAP |

## Current focus

**Xcode Cloud Release run 9 is archiving 1.0.0 (9) from `main` (`43171651-b3e4-49ff-ac98-47acc82ba01d`) and is not submitted.** The description in App Store Connect now mentions milestone notices. Run 8 archived the same build number, then the App Store export rewrote it to 8, so TestFlight still has build 8 until run 9 uploads. iPhone 6.9" and iPad 13" screenshots were replaced on 2026-11-04. The Duo set is still the earlier capture because Device Hub has no pose buttons. Finishing See the introduction now saves the check-in time, reminder and lock choices, and any new vices or habits. What's New waits until the first release is live. Submit still waits on the age-rating questionnaire, App Privacy confirmation, the open device-QA rows, and the 7-day dogfood (or a waiver). Post-launch order is in `FutureIdeas/backlog.md` (App Intents first).

The app has never shipped. Build 5 was archived on 2026-06-22 and never uploaded. There is no production data to migrate.

## Release history

| Version | Build | Date | Channel | Notes |
|---------|-------|------|---------|-------|
| 1.0.0 | 5 | 2026-06-22 | Archive | Pre-overhaul Xcode archive. Not uploaded. |
| 1.0.0 | 6 | 2026-10-28 | Repo | Build number bumped for the overhaul. Not archived. |
| 1.0.0 | 7 | 2026-11-02 | TestFlight | Xcode Cloud run 6. Not submitted. |
| 1.0.0 | 8 | 2026-11-02 | TestFlight | Xcode Cloud run 7 (`e4de4fd6-f3ec-483f-9d20-19bc3b9195b0`). Not submitted. |
| 1.0.0 | 9 | 2026-11-04 | Repo | Xcode Cloud run 8 archived this number, then the export uploaded it as build 8. Not in TestFlight as 9. |

## Key docs

| Doc | Purpose |
|-----|---------|
| [`ongoing/recovery-overhaul-plan.md`](../ongoing/recovery-overhaul-plan.md) | Approved plan and progress log |
| [`Specs/README.md`](../Specs/README.md) | Current behavior specs |
| [`docs/feature-inventory.md`](feature-inventory.md) | Cut list and planned features |
| [`docs/release/app-store-copy.md`](release/app-store-copy.md) | Listing copy (rewritten at the end of the overhaul) |
| [`docs/release/todo.md`](release/todo.md) | 1.0.0 ship checklist |
| [`DaRules/scripts/trigger-xcode-cloud.sh`](../../../DaRules/scripts/trigger-xcode-cloud.sh) | Starts the Xcode Cloud archive |
