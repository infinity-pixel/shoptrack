# Sprint 19.5 — Simplified Chinese

## Behavior

- Profile → Language offers 简体中文 from every language. Settings use `Chinese`,
  mapped to Flutter `zh_CN`; the existing saved-language transition is reused.
- UI copy includes Lists, History, Profile, all eight theme names, editors,
  confirmations, hints, tooltips, accessibility labels, search, sharing, sync,
  backup/restore, empty states, errors and calendars. Technical diagnostic codes,
  brands and ISO currency codes remain intact.
- Default My List displays as 我的清单. User-written names and notes remain intact.
- Chinese uses LTR and the original scenery orientation. Arabic remains RTL.
- Dates use year/month/day ordering; manual entry and keyboard Next follow the
  same order. Gregorian and corrected Umm al-Qura remain separate calendar
  preferences, not a Chinese lunar-calendar feature. Stored civil dates do not
  change. Chinese ordinary interface digits remain 0–9.
- Currency names are searchable in Chinese. Number formatting still follows
  the existing per-currency Automatic rule or the user's explicit override.
- Shared text localizes quantity units when a translation callback is supplied;
  untranslated/default exports retain their previous unit symbols.
- A missing “No Date Range Selected” message found during the audit was added
  to Bangla and Arabic as well as Chinese.

## Locale-data provenance

Chinese currency display names and Islamic month names are from Unicode CLDR,
retrieved 27 September 2026:

- https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-numbers-full/main/zh
- https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-cal-islamic-full/main/zh

The Unicode License V3 is included and registered in
`lib/core/localization/shoptrack_currency_names.dart`. No new dependency,
runtime download or distributed Windows font is introduced.

Downloaded JSON SHA-256:

- currencies.json: `c23b7df1982deae53121f6665e3c27059c1e47640b167c3ce0e3bf5a64d13c8d`
- ca-islamic.json: `8a16b3564611f2f0ccb50f3413f6b6283a3a5748cad5cddb8dafec09942eb88d`

To regenerate the supported currency subset, download the first JSON to
`build/cldr_zh_currencies.json`, then run
`dart run tool/generate_chinese_currency_names.dart`. Review upstream changes
before accepting regenerated data.

## Verification and device acceptance

Full regression suite: **389 passed**, 13 optional visual tests skipped. The
dedicated Chinese run with a real CJK font passed **15 tests**, including its
optional visual preview. The generated calendar, editor, range and Appearance
images were inspected. Static analysis is clean.

`test/sprint_19_5_test.dart` checks translation-key parity, placeholders, literal
interface-label coverage, all offered currencies, Chinese search, settings
restart/failure, Arabic-to-Chinese direction changes, authored-name preservation,
shared units, all eight themes, manual date focus order, dialogs, and
320×640 / 640×360 layouts with 1.3× text scaling.

Optional real-font previews use `SHOPTRACK_PREVIEW_FONT`, inspect calendar
preferences, date range, Appearance and the priced editor. Preview images remain
under ignored `build/sprint_19_5`; ordinary tests do not require a Windows font.

No Debug APK is built for this sprint. On the phone, verify native CJK font
fallback, the Chinese keyboard the user chooses, larger system fonts, language
switching in both directions, and native share destinations. Provider-owned
Google/Android dialogs follow their own locale behavior. Google/Firebase
availability in mainland China is not changed or guaranteed by translation.
