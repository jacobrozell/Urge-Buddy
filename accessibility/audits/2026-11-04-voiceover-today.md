# VoiceOver tree, Today and check-in, 2026-11-04

iPhone 17 simulator, iOS 26.5, `D6E88C26-060A-4FF9-B5ED-8A25F6379A5B`. Launch arguments `-ui_testing -skip_onboarding -seed_demo`. This is not a device VoiceOver pass. Speech, Magic Tap, the escape gesture, and drag reorder were not run.

`idb` 1.1.7, companion 1.1.8. The first `describe-all --json` died with `Invalid number value (NaN) in JSON write` after the tree was fetched. Labels below are from that companion log. A later JSON dump, after the fixes, is the second list.

## Today, before the fixes

Swipe order. Role 2 is a button, 6 is a heading, 13 is adjustable, 14 is static text. No element had a hint except Drink water's logger, "Log one". No custom actions.

- "Urge Buddy"
- "Add something" (`today.add`), 27×36
- "Today" (heading)
- "Wednesday, November 4, 2026"
- "Daily check-in, Check in · 2 things left · about 10 seconds" (`today.checkInBanner`)
- "Urge surfing. An urge rises and passes, like a wave." (`today.urgeSurfing`)
- "Dismiss" (`xmark`), 12×12
- "Quitting" (heading)
- "Alcohol, 8 days free, 19 hours 48 minutes into day 9 · $176.00 saved, Next: 14 days (in 6 days)" (`today.viceCard…`), one button
- "Social media, 6 days free, 6 hours 33 minutes into day 7, Next: 7 days (in 1 day)", one button
- "I'm having an urge" (`today.sosButton`)
- "Tab Bar"
- "Cutting back" (heading)
- "Smoking, 3 of 8 cigarettes today, 5 left, Down 60% from 20 cigarettes a day" (`today.cutBackCard…`), 337×36
- "Smoking" (`today.cutBackStepper…`), value `nan`, 207×44
- "Building" (heading)
- "Drink water, 5 of 8 glasses · 2-day run" and, as a second stop, "Drink water" value "5 of 8 glasses", 33×33
- "Go for a walk, 5-day run" and "Go for a walk, not done", 22×22
- "Call a friend, 3-day run, Don't miss twice" and "Call a friend, not done", 22×22

Alcohol is one button. The name and "days free" are in that label. The clock and the savings are in the same label, not separate stops. The clock is spoken as "19 hours 48 minutes into day 9", not "19h 48m". Headings rotor: Today, Quitting, Cutting back, Building.

## What failed

- Dismiss was a 12×12 button. The glyph was the accessibility frame.
- The habit log controls were 22×22 or 33×33.
- The Smoking title button was 36pt tall.
- The Smoking stepper's accessibility value was `nan`, which is what made `describe-all` drop the JSON. XCUITest on the same identifier read the string "3 cigarettes".

`idb ui tap` did not run. Companion 1.1.8 looks for SimulatorKit under `Xcode.app/Contents/Developer/Library/PrivateFrameworks`. It is at `Xcode.app/Contents/SharedFrameworks`.

## Check-in

`UrgeBuddyUITests.testVoiceOverTodayAndCheckIn` tapped `today.checkInBanner`, then the first `checkIn.free.` button. Before the tap the element's own snapshot line was:

`Button, {{32.0, 180.3}, {165.0, 44.0}}, identifier: 'checkIn.free.41398271-85E1-42BD-8710-7D628C088AB6', label: 'Free today'`

That line did not contain Selected. After the tap, the same line did. The companion JSON has no traits field, so Selected is not visible in an idb dump. The Today tab's own line does contain Selected, which is the selected tab.

## Today, after the fixes

`describe-all --json` succeeded. Same swipe order, with these changes:

- "Dismiss" (`today.urgeSurfing.dismiss`) is 44×44
- The Smoking title button is 338×44
- "Smoking" stepper value is "3 cigarettes", and its type is Button
- Each habit logger (`today.habitToggle…`) is 44×44, and the name button beside it is at least 44pt tall
- Alcohol is still one button: "Alcohol, 8 days free, 19 hours 59 minutes into day 9 · $176.00 saved, Next: 14 days (in 6 days)"

"Add something" (`today.add`) is still 27×36. That is the system toolbar plus.

## Still needs a device

Hearing the clock, Magic Tap, the escape gesture, and drag reorder. The tree says the clock is the words "19 hours 59 minutes", which is what VoiceOver would read from the label. This run does not mark the device VoiceOver row in `docs/release/todo.md` done.
