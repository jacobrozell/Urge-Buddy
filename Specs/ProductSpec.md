# TrackBoth Product Spec

> Spec governance: behavior changes update the matching spec in the same commit.


This spec is the product contract for the recovery overhaul. It was copied from the approved plan (2026-10-28).

## 2. Product thesis and psychology

### 2.1 One-sentence product

> **Urge Buddy helps you quit what's hurting you and build what helps: a 10-second daily check-in, a tool for riding out urges, and progress a slip can't erase.**

Positioning: *"Quit vices. Build habits."* The name is the moment you need the app. Quit one thing and build its replacement stays the product, carried by the subtitle. That's grounded in habit-reversal research: a behavior you remove leaves a gap, and a competing behavior should fill it.

### 2.2 The psychology the design is built on

Every feature below traces back to one of these. If a feature can't be traced, it gets cut.

| Principle | Source (for the specs) | What it means for TrackBoth |
|-----------|-----------------------|-----------------------------|
| **Abstinence violation effect (AVE)** | Marlatt & Gordon, *Relapse Prevention* (1985) | After a lapse, people who blame themselves and feel all-or-nothing are much more likely to fully relapse. **So:** a slip restarts the current run but never erases total free days, savings, or "27 of the last 30 days". Slip copy is compassionate and frames the slip as information. |
| **Urge surfing** | Bowen, Chawla & Marlatt, *Mindfulness-Based Relapse Prevention* (2010) | Urges rise, peak and pass like a wave. Watching them instead of obeying them weakens them. **So:** the core in-the-moment feature is a guided "ride it out" screen with breathing, a timer, your reasons, and your plan. |
| **Implementation intentions** | Gollwitzer (1999) | "If X happens, then I will Y" plans roughly double follow-through. **So:** every vice has one optional "When I feel the urge, I will…" plan, shown during urges and edited after slips. |
| **Motivational interviewing / personal values** | Miller & Rollnick | Reasons you put in your own words beat generic motivation. **So:** onboarding asks *why* and saves the answer as the first Reason. Reasons come up during urges and after slips. |
| **Trigger awareness (HALT and friends)** | Recovery practice (Hungry, Angry, Lonely, Tired) | Seeing your own patterns builds self-efficacy. **So:** slips and urges get optional one-tap trigger tags. Progress shows your top triggers and your hardest time of day. |
| **Fogg Behavior Model: B = MAP** | BJ Fogg, *Tiny Habits* | Behavior needs Motivation + Ability + a Prompt. **So:** a daily prompt (one notification), maximum ability (the check-in takes about 10 seconds), and an immediate celebration (haptic + animation). |
| **Missing one day doesn't break a habit** | Lally et al. (2010), *How are habits formed* | One missed day didn't measurably hurt habit formation. **So:** habit streaks follow "never miss twice": one missed day pauses the streak, two in a row end it. |
| **Self-compassion predicts recovery better than self-criticism** | Neff; addiction research on shame | **So:** no red, no ✕, no "failed". Slips use amber and calm wording. |
| **Language matters** | NIDA, *Words Matter* | "Clean/dirty" stigmatizes. **So:** use "free" ("12 days free"), "slip" (not "relapse" or "fail"), and "use" (not "abuse"). |

### 2.3 The core loop

```
          ┌────────────────────────────────────────────────────────────┐
          │                                                            │
   PROMPT │  Daily reminder at your chosen time (one per day, max)     │
          │  + an urge (internal) → home-screen quick action "Urge"    │
          ▼                                                            │
   ACTION │  Check-in: "Free today?" per vice + tick helper habits      │
          │  (≤10 seconds)   ─or─   Urge flow: ride it out (2–10 min)   │
          ▼                                                            │
   REWARD │  Immediate: haptic + "13 days free · $104 saved"            │
          │  Milestones: 1, 3, 7, 14, 30… days (re-earnable after slip) │
          │  Urges beaten counter: "That's 6 urges you've ridden out"  │
          ▼                                                            │
   INVEST │  Reasons, your if-then plan, trigger tags, helper habits →  │
          │  makes the next urge flow more personal and more effective │
          └──────────────────────────────── (next day) ─────────────────┘
```

**Ethical guardrail:** success means the user needs the app *less* over time. We don't optimize for time-in-app. No variable-reward slot mechanics, no streak freezes you pay for, no guilt notifications, at most one reminder a day plus milestone notices, no leaderboards, no social comparison.

### 2.4 What we are deliberately NOT building

| Cut | Why |
|-----|-----|
| Goals tab, weekly/monthly/yearly targets | Daily targets and limits shipped instead (§4.10). Weekly goals are in `FutureIdeas/backlog.md`. |
| Per-entry mood chips, starred entries | One optional mood and note per day replaces them (§4.10). Trigger tags still cover slips and urges. |
| Charts tab (line, bar, heatmap), chart PNG/PDF export | Generic analytics. Replaced by a calendar plus three recovery stats. |
| Multiple color themes, font picker | Decoration. One calm palette that follows system light/dark. |
| Per-device layout files (4 per screen) | 4× the QA work. **Ship one adaptive layout per screen** (D6, §8.7), not separate orientation files. |
| Widget, Watch, Live Activities, Shortcuts | Post-launch. A single "days free" widget is Phase 14 (optional). |
| Launch splash animation | Delays the moment of need. The system launch screen is enough. |
| Week-start picker | Use `Calendar.current.firstWeekday` (follows the user's locale). |
| Placeholder "My habit / My vice" rows | Fake data. Onboarding requires one real choice. |
| Demo data in Release | Debug and screenshots only. |

---

## 3. Decision gates (defaults chosen — owner may override)

The agent proceeds with the **Default** unless the owner has written something different in the Owner column. **Owner answers recorded 2026-10-28.** Gates with an empty Owner cell use their default.

| # | Decision | Default | Owner |
|---|----------|---------|-------|
| D1 | Data reset. The app has never shipped, so the schema is redefined from scratch with a **new store file**. Old exports stay importable. | **Yes** | ✅ Yes, start fresh (app not released) |
| D2 | Keep habits? | **Yes**, framed as "Building" (helper habits that replace the vice). A user can still track habits only. | |
| D3 | How vice days count | **Presumed free:** time counts up from the quit date, and only *logged slips* break it. Check-ins *confirm* days (solid in the calendar); unconfirmed past days count but look hollow. Same model as I Am Sober. | ✅ Yes, same as I Am Sober |
| D4 | Habit streak rule | **Never miss twice** (§6.6) | |
| D5 | Vocabulary | **"Free / slip"** (not "clean / relapse / fail") | ✅ Yes |
| D6 | Devices | **iPhone and iPad, portrait and landscape, iPhone Duo-ready** via size-class adaptive layout (§8.7). | ✅ Shipped on branch (adaptive-layout plan, 2026-10-31) |
| D7 | Widget | **Post-launch** (Phase 14, optional) | |
| D8 | App lock (Face ID/passcode) | **Ship it, off by default, offered during onboarding** | |
| D9 | App Store name/subtitle | Name **Urge Buddy**. Subtitle **"Quit vices. Build habits."** (25/30 chars) | ✅ Urge Buddy, 2026-11-01 |
| D10 | Version | **Stays 1.0.0** (never shipped). Build number continues from **6**. | |
| D11 | Monetization | **Free**, no IAP (existing decision) | |
| D12 | Telemetry | **None** | |
| D13 | Live clock granularity | **Minutes** (`12d 4h 13m`). Calmer than a seconds ticker. | |

---

## 4. Target product

### 4.1 Information architecture

Three tabs. That's it.

| Tab | SF Symbol | Purpose |
|-----|-----------|---------|
| **Today** | `sun.max` | Check-in, vice cards with live free-time, helper habit checklist, the **"I'm having an urge"** button. |
| **Progress** | `chart.line.uptrend.xyaxis` | One card per metric with its key numbers → tap for Metric Detail (calendar, reasons, plan, triggers, history editing). |
| **Settings** | `gearshape` | Reminders, app lock, appearance, backup/restore, delete, get help now, about. |

Presented flows (sheets or full-screen covers): **Check-in**, **Urge**, **Slip**, **Celebration**, **Add/Edit metric**, **Day editor**, **Onboarding**, **Lock screen**.

Entry points into the **Urge** flow: the Today button, the home-screen quick action (long-press the app icon), the `trackboth://urge` URL, and the "Having an urge?" link in the Check-in sheet.

### 4.2 Today screen

```
┌──────────────────────────────────────┐
│ Today                             +  │  large title; + adds a metric
│ Monday, November 2                   │  date under the title, not in the toolbar
│                                      │
│ ┌──────────────────────────────────┐ │
│ │  4                               │ │  Check-in card, brand fill, while
│ │  days in a row                   │ │  today is still open. Afterward:
│ │  Check in · 3 things left · …  › │ │  "5 days in a row" on brand soft.
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ [wind]  Urge surfing       ›  ×  │ │  opens the explainer; × or the row
│ │ An urge rises and passes…        │ │  dismisses it for good. Shown while a vice is active, until dismissed
│ └──────────────────────────────────┘ │
│                                      │
│ QUITTING                             │  section header
│ ┌──────────────────────────────────┐ │
│ │ [wineglass]  Alcohol           › │ │  ViceCard; chevron means it opens
│ │ 12 days free                     │ │  big rounded number
│ │ 12d 4h 13m  ·  $96 saved         │ │  live (TimelineView, minute)
│ │ ● ● ● ○ ● ● ◐                    │ │  ●confirmed ○presumed ◐today ▲slip
│ │ M T W T F S S                    │ │  weekday initials under the dots
│ │ Next milestone: 14 days (2 days) │ │
│ └──────────────────────────────────┘ │
│                                      │
│ BUILDING                             │
│ ┌──────────────────────────────────┐ │
│ │ ○  Go for a walk       5-day run │ │  HabitCheckRow (tap circle = done)
│ │ ●  Call a friend       2-day run │ │
│ │ ○  Drink water   Don't miss twice│ │  at-risk hint (amber, gentle)
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │      [wind]  I'm having an urge  │ │  SOSButton — pinned above tab bar
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│   Today      Progress      Settings  │
└──────────────────────────────────────┘
```

Rules:
- Order: date under the title → check-in card → urge-surfing row (until dismissed) → "Quitting" (vices, by `sortOrder`) → "Cutting back" → "Building" (habits) → SOSButton under the list.
- The date is gray subtitle text ("Monday, November 2"), including at large accessibility sizes. It is not a toolbar item. The check-in sheet has no date in the toolbar either.
- The check-in card stays once anything is tracked. While today is open it is a brand-filled button: the streak on one line (when there is one) and "Check in · N things left · about 10 seconds" (or "1 thing left"). After today is answered it becomes "N days in a row" and "You checked in today." The streak is consecutive days the check-in was answered, including today only after it is answered. A presumed-free day does not count. A logged slip does. One missed day ends the run, and the app does not say so. The urge button sits under the list, not over the last row.
- The urge-surfing row shows while a vice is active, until the person taps it or dismisses it. Either choice sets `Preferences.hasDismissedUrgeSurfingTip` and the row stays gone. The explainer remains in Settings → Support and inside the urge flow.
- One Add button in the toolbar (`today.add`, label "Add something") opens Add metric. The type picker chooses quitting or building. Section headers have no +. A section is shown only when it has a card. On a wide window the quitting column and the building column fill the width, side by side, wider than the text column above them. Empty Today still offers "Quit or cut back" and "Build a habit".
- Vice cards and cut-back cards show a trailing chevron. It is hidden from VoiceOver; the card is still one button.
- The SOSButton shows only if there's at least one active vice.
- Tapping a ViceCard opens Metric Detail (pushes onto the Progress tab's stack: switch tab, then push. Or present Metric Detail as a sheet from Today, which is simpler; **use the sheet**).
- Tapping a habit's circle toggles done for today (haptic `.success` on done, `.selection` on undo). Tapping the row text opens Metric Detail.
- Empty state (no metrics; only reachable after deleting everything): "Start with one thing", then "Quit or cut back" (adds a vice) and "Build a habit" (adds a habit).
- If yesterday is unconfirmed for any vice **and** the user opened the app before noon, show one dismissible row above the banner: "Yesterday: were you free from Alcohol?" with `ChoiceButton`s [Yes] [I slipped]. (Keeps the calendar honest without nagging.)

### 4.3 Daily check-in (the core ritual)

Sheet, `.presentationDetents([.medium, .large])`.

```
Daily check-in

Alcohol
 [✓ Free today  ]   [ I slipped ]

Social media
 [  Free today  ]   [ I slipped ]

Building
 ○ Go for a walk
 ○ Call a friend

Having an urge right now? →            (closes this sheet, opens Urge, then brings check-in back)

[ Done ]                                 (enabled once every vice has an answer)
```

- "Free today" and "I slipped" are `ChoiceButton`s, equal width. "Free today" → `RecoveryStore.markFree(metric, on: today)`, and the button fills `Brand` with a checkmark. "I slipped" is never shown selected.
- "I slipped" → present the **Slip flow** with `day = today`. When it finishes, that row shows "Slip logged · thanks for being honest" and can't be toggled back from here (fix it in the Day editor).
- The yesterday prompt uses the same `ChoiceButton`s for "Yes" and "I slipped".
- Habit rows toggle done.
- **Done** → `CheckInCompleteView` (inside the same sheet): an animated check, the check-in streak in a big number ("5" / "days in a row" / "You checked in today."), then one line per vice ("13 days free · $104 saved"), with padding and spacers between the badge, the streak, and the lines. Then any milestone → Celebration. The celebration sheet uses the same breathing room. **Keep going** records the milestone and dismisses the sheet. A 7-day vice milestone asks for a review only after that sheet is gone.
- Check-in counts as **complete** for a day when every active vice has an entry for that day. Habits are optional for completeness.

### 4.4 Urge flow ("I'm having an urge")

`fullScreenCover`, calm background. Four steps:

1. **Which one?** Skipped when there's only one active vice. A list of active vices.
2. **How strong?** Five big buttons (1 Mild … 5 Intense), default 3, with a "Skip" option. Creates an `UrgeEvent(outcome: .inProgress)`.
3. **Ride it out**
   - A `BreathingCircle`: a soft orb grows for 4s ("Breathe in") and shrinks for 6s ("Breathe out"), with a glow and ripples across the full breath. A slow light wash sits behind this screen. Under Reduce Motion it shows only the text cue, switching every 4s/6s, and the wash is hidden.
   - Countdown starting at **5:00**, with a "+5 min" button. Once that countdown scrolls off the screen, the time stays in the top bar. One card holds the intro — *"This is urge surfing. The urge rises, peaks, and passes, like a wave. Breathe, and watch it."* — and a **What is urge surfing?** line under it. The same link is on the strength step, on Today until that row is dismissed, and in Settings → Support. It opens a short explainer: what an urge wave is, how to watch it instead of acting on it, and what to do on this screen. After the urge passes, one line names what they just did: "You stayed with the wave until it fell. That's urge surfing."
   - **Your why** card: a short quote for each reason. Swipe between them (or a list under Reduce Motion).
   - **Your plan** card, if `ifThenPlan` is set: "When I feel the urge, I will: …"
   - **Try one instead:** each habit is a row with its icon and an open circle. Tapping marks it done today (the circle fills, plus a haptic). Tap again to clear it. A field on the card adds another habit. It shows up in the list immediately and on Today. A name that is already there is not added again.
   - Buttons: **[The urge passed]** (primary) and **[I slipped]** (secondary, plain text style). In portrait they stay pinned under the scroll view, inside the readable column, so the journal field is never covered. In landscape (short height) they stay at the end of the support column. They hide once "I slipped" opens the journal confirm step. The X in the corner asks "How did it go?" → passed / slipped / not sure.
   - When the timer hits 0: a soft haptic, the short `urge-timer-done` tone (Mixkit's unlock notification; silent switch wins), and "Still with it? You can add 5 minutes, or check in with yourself." Adding 5 minutes and letting it run out plays the tone again. It does not play when the ride opens already at 0.
4. **Outcome**
   - *Passed* → `outcome = .resisted` → screen: "You rode it out." + "That's **N** urges you've beaten." + optional "What set it off?" trigger chips → **Done**.
   - *Slipped* → `outcome = .slipped` → Slip flow, prefilled with the triggers picked here. The urge's triggers are copied onto the slip entry.
   - *Not sure* → `outcome = .unknown`, back to Today.

### 4.5 Slip flow

Sheet, one scrolling form, **no red anywhere**.

```
Thanks for being honest.
A slip is information, not failure. Let's learn from it.

When?   [Just now] [Earlier today] [Yesterday] [Pick a day…]
What was going on?  (chips, multi-select — TriggerTag list §6.7)
Anything else? (optional note)
Next time I feel the urge, I will…  (prefilled with current plan)

[ Save ]
```

`occurredAt` rules: *Just now* and *Earlier today* = `now`. *Yesterday* = start of today − 1 second (23:59:59 yesterday). *Pick a day* = that day at 23:59:59, or `now` if it's today. The date picker range is from `startOfDay(metric.startedAt)` to today.

On save: `RecoveryStore.logSlip(...)`, and if the plan text changed, update `metric.ifThenPlan`. Then show **SlipSummaryView**:

> **Your free clock restarts from here.**
> You still have **27 of your last 30 days** free and **$135** saved. That progress is real and it stays.
> *[Reason card: first Reason]*
> Two equal-height tiles: "**27 of 30**" / Recent days free, and the amount still saved.
> Need more support? is a `SecondaryButton` → Get help now (Crisis resources, §4.9)
> **[Back to Today]**
>
> The summary has no Close. Close stays on the form. In landscape, Back to Today stays in the toolbar.

Haptic: `.impact(weight: .light)`. Never `.error`.

### 4.6 Language rules (applies to all copy)

| Use | Don't use |
|-----|-----------|
| free, free from, days free | clean, sober (unless the user typed it), dirty |
| slip, slipped | relapse, fail, failed, broke, ruined, lost |
| urge | craving is OK; temptation is moralizing |
| "Thanks for being honest" | "Oops", "Too bad", "Try harder" |
| "Your clock restarts" | "Your streak was reset to 0" |
| "Don't miss twice" (habits) | "You'll lose your streak!" |
| Second person, short sentences, plain words | Clinical jargon, exclamation-mark spam (max one per screen) |

Notification copy is never guilt-based. In **discreet mode** it never names the vice.

### 4.7 Progress tab

- Top: one summary card, inset so its edges line up with the metric list, with compact space before the next group. The lead number is **Total saved** when any vice has a cost, otherwise the **check-in streak**. Under it, a compact row: **Urges beaten**, **Days checked in** (last 30), and the streak when it is not already the lead.
- Then one `ProgressMetricCard` per active metric (vices first). For a vice: "12 days free · longest 40 · 27/30 days". For a habit: "5-day run · best 14 · 22/30 days". A chevron leads to **Metric Detail**.
- An "Archived" disclosure at the bottom lists archived metrics (they can be restored).

**Metric Detail** (`MetricDetailScreen`) uses one summary panel and, on a wide or short screen, a second column. Facts are label-and-value rows inside the panel (they stack only at accessibility text sizes). Landscape phones split the columns from 520pt wide.

1. **Summary panel:** icon, live free clock (vice) or run count (habit), then rows for the four stats, the next milestone, and the quit date or start date. Saved shows the daily cost as a caption, or "—" plus **Add a daily cost** when no cost is set. Habits show "Don't miss twice" in this panel when yesterday was missed and today is still open. Vice rows: Current run, Longest run, Free last 30 (`free/counted`), Saved. Habit rows: Current run, Best run, Done last 30, Done all time.
2. **Calendar:** month grid with month paging back to `startedAt`, plus a legend for the marks on screen. On a wide or short screen this sits under the summary, beside the record. Day cell states: confirmed free (solid brand), presumed free (outlined brand), slip (amber mark), habit done (solid indigo), missed (hollow), before start (dimmed). Future days are a gray number only, with no mark, and do not open the editor. VoiceOver reads just the date. Tap a past day → **Day editor** sheet: vice = [Free] [Slipped] [Clear]; habit = [Done] [Not done]. Changing to "Slipped" opens the Slip flow for that day.
3. **Record panel** (vices, one card, only once there is something to show): urge rows for beaten, slipped, not sure, and average strength. In-progress urges are left out. Until the first finished urge, that sentence sits under the Urges label, across the card, in footnote text and `TextSecondary`. **Patterns** (once there are ≥3 slips + urges combined): top 3 triggers as horizontal bars with counts; hardest time and, when it isn't a tie, hardest weekday (§6.8). Hardest time and day count slips and non-resisted urges. **Recent:** the latest slips, ridden-out urges, and "not sure" urges (up to 8). Each row shows when, trigger names, strength, and any note. A slip picks up the strength of a slipped urge on that same day.
4. **Your reasons:** a list with add, tap-to-edit, and a row menu to edit, move up, move down, or delete. The first one is marked Primary, with a line that it is what you see when you slip.
5. **Your plan:** the if-then prefix and the plan text. **Save** appears when the text differs from what's stored.
6. Toolbar → **Edit** (MetricForm: name, icon, start date, cost per day, archive, delete). The name is the navigation title.

### 4.8 Onboarding (9 short steps, all skippable except choosing a vice)

The progress bar is filled for the current step, so the first page already shows a short teal segment and the last page is full.

| Step | Screen | Saves |
|------|--------|-------|
| 1 | **Welcome.** "Quit what's hurting you. Build what helps." Three lines on how it works. [Get started] | — |
| 2 | **Urge surfing.** The same lesson as `UrgeSurfingExplainer`: what an urge wave is, how to watch it, and what to do when one hits. [Next] | — |
| 3 | **What do you want to quit?** Preset grid (§13.2) plus "Something else…" (text field). Multi-select, max 3. A "I only want to build habits" link skips to the habits step. **Need ≥1 vice or the habit-only link.** | draft vices |
| 4 | For each chosen vice (one page each): **Quit or cut back.** Quit asks **When did you last [use/do] it?** [Today] [Yesterday] [Pick a date] → `startedAt` (Today = now; Yesterday/Pick = that day at 23:59:59, as with slips). Cut back asks usual amount and a daily limit (required; zero is fine). **What does it cost you per day?** Optional currency field. Number pads get a keyboard **Done** button. | `startedAt`, `costPerDay`, tracking |
| 5 | **Why do you want to quit [first vice]?** Multiline text with prompt chips that insert a starter ("For my health…", "For my family…", "To save money…", "To feel in control…"). Skippable. | first `Reason` |
| 6 | **What helps you?** Helper habit presets (§13.3) + custom, multi-select, max 3. Skippable. | draft habits |
| 7 | **Daily check-in time.** Time picker, default 8:00 PM. Copy: "We'll send one gentle reminder a day, and a note when you reach a milestone." [Turn on reminders] → *then* call the system permission prompt. [Not now]. | reminder prefs |
| 8 | **Keep it private?** "Lock Urge Buddy with Face ID." [Turn on] [Not now]. Hidden if the device has no passcode set. | lock pref |
| 9 | **Important.** "Urge Buddy is a self-help tool, not medical treatment. Stopping some substances suddenly, like alcohol, benzodiazepines, or opioids, can be dangerous. Talk to a doctor. If you're in crisis, help is in Settings → Get help now." [I understand] | `hasAcceptedDisclaimer` |

Finish → create everything in one `RecoveryStore` transaction → land on Today with the CheckInBanner showing.

### 4.9 Settings

| Section | Rows |
|---------|------|
| Reminders | Daily check-in (toggle) · Time (hour/minute picker, disabled while Daily check-in is off) · Milestone notifications (toggle) · Discreet notifications (toggle; footer: "Hides habit and vice names on your lock screen.") |
| Privacy | Lock with Face ID / Touch ID / Passcode (label adapts to `LAContext.biometryType`) |
| Appearance | System / Light / Dark (segmented) |
| Your data | Export backup (.json) · Import backup · Delete all data (destructive, double-confirm) |
| Support | **See the introduction** (replays onboarding; Done saves the check-in time, reminder and lock choices, and any new vices or habits; a name already tracked, including an archived one, skips the quit date, cost, reason, and cut-back pages; existing tracking stays) · **What is urge surfing?** (→ `UrgeSurfingExplainer`) · **Get help now** (→ `CrisisResourcesView`) · Contact support (`AppLinks.support`) · Privacy policy (`AppLinks.privacy`) · Rate Urge Buddy |
| About | Version (build) · Disclaimer text · Accessibility statement (`AppLinks.accessibility`) |
| Debug (DEBUG builds only, `ProductSurface.showsDebugTools`) | Seed demo data · Clear data · Reset onboarding · Fire test milestone · Schedule test reminder in 10s |

**CrisisResourcesView** (static content, all links tappable):
- "If you're in immediate danger, call **911** or your local emergency number." (`tel:911`)
- **988 Suicide & Crisis Lifeline** (US): call or text **988** (`tel:988`, `sms:988`)
- **SAMHSA National Helpline** (US): **1-800-662-4357**. Free, confidential, 24/7, English and Spanish. (`tel:18006624357`)
- Outside the US: **findahelpline.com** (`https://findahelpline.com`)
- "Stopping alcohol, benzodiazepines, or opioids suddenly can be dangerous. Talk to a doctor or pharmacist."

### 4.10 Cutting back, amounts, and day mood

**Quit or cut back.** Each vice has a mode (`ViceMode`), chosen in onboarding and the metric form.

- **Quit** is everything above: free clock, milestones, slips.
- **Cut back** tracks a count per day against a **daily limit** (0 allowed), with an optional unit ("cigarettes") and **usual per day** (baseline). It starts today. There is no free clock and there are no milestones.
  - Today shows a `CutBackCard` in a "Cutting back" section: "3 of 8 cigarettes today", a limit bar, a stepper, last 7 days, and "Down 60% from 20 cigarettes a day" (or the 7-day average when there's no baseline).
  - Going over the limit is amber, never red: "Over your limit today. Tomorrow is a fresh start."
  - Calendar: within limit (solid brand), over (amber triangle), not logged (hollow). An unlogged day is unknown, never presumed.
  - Check-in asks "How many today?" with a stepper. Done logs the shown amount, so an untouched row logs 0.
  - Urge flow: "I had one" adds 1 and closes. It doesn't open the slip flow.
  - Detail tiles: daily limit, 7-day average, within the limit in the last 30 days, usual, and saved (needs a baseline and a cost).
  - Switching to quit starts the free clock now.
- **Amount habits.** A habit can track an amount with a **daily target** ("8 glasses"). The row shows a progress ring that adds a step on each tap (5 when the target is 20 or more). Long-press removes one. Below the target is partial (hollow square); reaching it counts as done for the run.
- **Day mood and note.** One optional mood (Rough, Low, Okay, Good, Great) and note per calendar day. It's asked at the end of check-in, can be edited in the Day editor, and the last five appear under "Recent days" on Progress. Those rows stay on the list. They are not links, so they do not open Metric Detail.



## 9. Copy deck (key strings — put in `RecoveryCopy`)

| Key | String |
|-----|--------|
| `daysFree(n)` | n == 1 ? "1 day free" : "\(n) days free" |
| `clock(d,h,m)` | d > 0 ? "\(d)d \(h)h \(m)m" : h > 0 ? "\(h)h \(m)m" : m > 0 ? "\(m)m" : "Just started" |
| `saved(amount)` | "\(currency) saved" (`Decimal.FormatStyle.Currency(code: Locale.current.currency?.identifier ?? "USD")`) |
| `freeOfLast(free, counted)` | "\(free) of last \(counted) days free" |
| `habitRun(n)` | n == 1 ? "1-day run" : "\(n)-day run" |
| `dontMissTwice` | "Don't miss twice" |
| `nextMilestone(t, inDays)` | "Next: \(t) days (in \(inDays) \(inDays == 1 ? "day" : "days"))" |
| `checkInBanner(left)` | left == 1 ? "Check in · 1 thing left · about 10 seconds" : "Check in · \(left) things left · about 10 seconds" |
| `addSomethingToQuit` | "Quit or cut back" |
| `addAHabit` | "Build a habit" |
| `sosButton` | "I'm having an urge" |
| `urgeIntro` | "This is urge surfing. The urge rises, peaks, and passes, like a wave. Breathe, and watch it." |
| `whatIsUrgeSurfing` | "What is urge surfing?" |
| `urgePassed(n)` | "You rode it out. That's \(n) \(n == 1 ? "urge" : "urges") you've beaten." |
| `slipTitle` | "Thanks for being honest." |
| `slipSubtitle` | "A slip is information, not failure. Let's learn from it." |
| `slipSummaryTitle` | "Your free clock restarts from here." |
| `slipSummaryBody(free, counted, saved?)` | "You still have \(free) of your last \(counted) days free\(saved.map { " and \($0) saved" } ?? ""). That progress is real and it stays." |
| `daysUnit(n)` | n == 1 ? "day" : "days" |
| `milestoneVice(t, name)` | t == 1 ? "Your first day free from \(name)." : "\(t) days free from \(name)." |
| `milestoneHabit(t, name)` | "\(t)-day run: \(name)." |
| `disclaimer` | see §4.8 step 8 |
| `cutBackProgress(amount, limit, unit)` | "\(amount) of \(limit) \(unit) today" |
| `overLimitToday` | "Over your limit today. Tomorrow is a fresh start." |
| `reduction(pct, baseline, unit)` | "Down \(pct)% from \(baseline) \(unit) a day" |
| `howManyToday(limit)` | "How many today? Your limit is \(limit)." |
| `howAreYouFeeling` | "How are you feeling?" |

Plurals: simple ternaries are fine for 1.0 (English only). Leave `SWIFT_EMIT_LOC_STRINGS` on.


### 13.1 Glossary
- **Vice / Quitting:** something the user wants to stop. Shows "days free".
- **Habit / Building:** a helper behavior the user wants to do daily. Shows "N-day run".
- **Run:** the current unbroken stretch (vices: since the last slip; habits: never-miss-twice).
- **Presumed free:** a past day with no entry after the quit date. It counts as free but shows hollow.
- **Check-in:** confirming today for every active vice (habits optional).

### 13.2 Vice presets (`Presets.vices`)

| id | name | icon | "When did you last…" verb |
|----|------|------|---------------------------|
| alcohol | Alcohol | `wineglass` | drink |
| smoking | Smoking | `smoke` | smoke |
| vaping | Vaping | `cloud` | vape |
| cannabis | Cannabis | `leaf` | use cannabis |
| gambling | Gambling | `dice` | gamble |
| porn | Porn | `eye.slash` | watch porn |
| social-media | Social media | `iphone` | scroll social media |
| gaming | Gaming | `gamecontroller` | game |
| junk-food | Junk food | `takeoutbag.and.cup.and.straw` | eat junk food |
| shopping | Impulse shopping | `bag` | impulse shop |
| caffeine | Caffeine | `cup.and.saucer` | have caffeine |

Custom vices use the verb phrase "do it". **Verify every SF Symbol name** in the SF Symbols app for iOS 18 before you commit. Replace any that don't exist.

### 13.3 Helper habit presets (`Presets.habits`)

| id | name | icon |
|----|------|------|
| walk | Go for a walk | `figure.walk` |
| exercise | Exercise | `figure.run` |
| water | Drink water | `drop` |
| reach-out | Call or text a friend | `phone` |
| breathe | Breathe / meditate | `wind` |
| journal | Journal | `book.closed` |
| outside | Time outside | `sun.max` |
| meal | Eat a real meal | `fork.knife` |
| sleep | In bed by 11 | `bed.double` |
| meeting | Support group / meeting | `person.3` |

### 13.4 References (cite in `Specs/ProductSpec.md`)
- Marlatt, G. A., & Gordon, J. R. (1985). *Relapse Prevention.* Guilford. (Abstinence violation effect.)
- Bowen, S., Chawla, N., & Marlatt, G. A. (2010). *Mindfulness-Based Relapse Prevention for Addictive Behaviors.* Guilford. (Urge surfing.)
- Gollwitzer, P. M. (1999). Implementation intentions. *American Psychologist, 54*(7).
- Lally, P., et al. (2010). How are habits formed. *European Journal of Social Psychology, 40*(6).
- Fogg, B. J. (2019). *Tiny Habits.* (B = MAP, celebration.)
- Miller, W. R., & Rollnick, S. *Motivational Interviewing.* (Change talk, personal reasons.)
- NIDA. *Words Matter: Terms to Use and Avoid When Talking About Addiction.*


## Verification

| Field | Value |
|-------|--------|
| Last verified | 2026-11-02 |
| Commit | ui-polish |

