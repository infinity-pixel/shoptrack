# Sprint 19.4: Arabic and calendar preferences

## Behavior

- Modern Standard Arabic joins English and Bangla, including dialogs, settings,
  sync explanations, currency names, sharing labels, and date controls.
- Direction-aware layout mirrors control placement and decorative scenery without
  reversing user text, money digits, or nondirectional icons. Arabic interface
  numbers use Arabic-Indic digits; numeric entry also accepts Western, Bengali,
  Arabic, and Persian digits.
- Language changes display an interaction-blocking, localized progress screen
  until the preference is saved and the new locale has painted. Reduced-motion
  mode uses a static icon. No artificial waiting period is added.
- Profile's Calendar preference is available in every language. Gregorian is
  the default. Hijri uses Umm al-Qura with an optional -2 to +2 day adjustment,
  a live preview, and a regional-date warning. Switching languages does not
  switch calendars.
- Dates selected in either calendar resolve to the same Gregorian shopping-day
  model. IDs, stored dates, Firestore paths, and merge behavior do not change.
  Calendar preferences are local settings. User-authored names remain untouched.

## Method and limitations

See [calendar provenance](umm_al_qura_calendar.md) for the bundled table's
source and license. The application supports selecting dates in 2000–2100.
Manual correction is a display preference, not a religious-date authority or
automatic regional moon-sighting service.

## Verification

Sprint tests cover translation-key parity, currency-name coverage, numeric input,
RTL scenery/control placement, persistence and failed writes, language switching,
exact share data preservation, calendar fixtures and round trips for every
selectable day at all five offsets. Widget coverage includes 320×640 and 640×360
at 1.3 text scale in all three languages. Optional preview tests accept
`SHOPTRACK_PREVIEW_FONT` and write images under ignored `build/`.

Local verification on 26 September 2026: analysis clean; full suite 360 passed
with 11 optional tests skipped; calendar/settings preview run 29 passed; Android
debug APK built successfully. Arabic calendar/settings and RTL scenery previews
were inspected. Desktop preview fonts do not establish Android font fallback.
The build warns that the current Firebase plugins still apply Kotlin Gradle
Plugin, which needs attention before a future Flutter toolchain upgrade.

Physical-device acceptance remains necessary for native keyboard behavior,
Arabic font fallback, animation feel, TalkBack, and device performance. No live
Firestore configuration or data is changed by this sprint.
