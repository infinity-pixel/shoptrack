# Sprint 19.5.1 — multilingual presentation refinements

## Scope

- Keep Gregorian civil-day storage and midnight rollover. No sunset/location
  feature, calendar migration, numerical change or synchronization change.
- Use localized abbreviated month names where they fit. Arabic full month names
  and other longer labels sit in allocated space immediately above the rings.
  The day inside the calendar is a localized number, without Chinese 日.
- Resolve hero fades to physical left/right alignments on each rebuild. The
  installed Flutter BoxDecoration painter caches a gradient shader by rectangle,
  not text direction; changing the actual decoration invalidates that cache.
- Bundle three small money-text weights and three taka-only glyph subsets.
  Keep LibreBaskerville for totals and the interface script fallback for localized
  digits/units. Currency selector width follows its ISO code and arrow only, with
  the existing narrow-screen price-field stacking behavior.
- Increase optical heading size for Arabic and Chinese, allow receipt headings
  to wrap, and underline only Total Amount. Currency rows are not rearranged.
- Preserve Today glow across languages/themes. Reduced motion stops its ticker
  and displays a steady, subtle highlight. The History search prompt can wrap
  on narrow/high-text-scale screens.

## Verification

The full suite passes 396 tests (14 optional visual tests skipped). Dedicated
regressions cover all four languages, all eight Today themes, 12 Gregorian and
12 Hijri months per language, all catalogue amount styles, RTL-to-LTR live
switches in both heroes, and currency selectors at 320×640 / 640×360 with 1.3×
text scale. Currency font provenance and reproduction are in
`currency_symbols.md`.

Static analysis is clean. The dedicated eight-check run with real-font preview
generation also passes. Inspected previews cover currency weights/signs, the
Bangla editor, four-language month badges and heroes, Chinese totals, and
Arabic/Chinese Hijri History in dark/light themes.

Optional real-font previews are generated with:

```
flutter test --no-pub test/sprint_19_5_1_test.dart --dart-define=SHOPTRACK_VISUAL_PREVIEW=true --plain-name "real font previews"
```

This opt-in local preview uses installed Windows Arabic/Bengali/Chinese fonts;
ordinary CI does not depend on them. Images go to ignored `build/sprint_19_5_1`.
They are not a claim of Galaxy A35 hardware acceptance.

## Device acceptance

1. Switch Arabic → Chinese → Bangla → English without restarting: the artwork
   and strongest fade must follow the appropriate text side.
2. Check the compact BDT code/arrow selector with no reserved symbol gap, USD
   bold price, and currency symbols in amounts; compare at enlarged system text
   size and in landscape.
3. Review Arabic Gregorian/Hijri month names just above the rings and Chinese
   day-only digits. Check the enlarged History/Lists headings in light and dark.
4. Confirm Today glows gently, reduced-motion mode is steady, and totals retain
   their full-width rows, fitting/tooltip behavior and LibreBaskerville styling.

No APK is built for this refinement. Commit and push were authorized after the
final code-only currency-selector adjustment.
