# Currency symbols and bundled glyphs

Sprint 19.4.1 updates the display metadata for SAR, MVR, AED and OMR to
Unicode currency signs U+20C1, U+20C2, U+20C3 and U+20C4 respectively. Currency
ownership, ISO codes, numeric values, serialization and sync are unchanged.
Other entries retain the symbols in the pinned money2 catalogue; this is not a
claim that every country's preferred typography has been independently audited.

Primary references checked September 2026:

- [Unicode currency-symbol names](https://www.unicode.org/Public/18.0.0/charts/nameslist/20a0/)
- [Saudi Central Bank](https://sama.gov.sa/en-US/Currency/SRS/Pages/default.aspx)
- [Central Bank of the UAE](https://centralbank.ae/en/our-operations/currency-and-coins/)
- [Central Bank of Oman](https://cbo.gov.om/omrsymbol)
- [Maldives Monetary Authority symbol guidelines](https://www.mma.gov.mv/files/currency/Currency%20Symbol%20Guideline.pdf)

System font coverage can lag behind official adoption. Two tiny, glyph-only
fallback fonts ship with the application; they cannot replace ordinary text.
Their licenses are bundled and registered in the application's license list.

## Reproducing the subsets

Run from the repository root, with Python and fonttools 4.66 installed (the
build helper also checks `build/font_tools`). Download the following build inputs:

- `build/gcc_currency.ttf`: [gcc_currency pinned source](https://raw.githubusercontent.com/fathah/gcc_currency/c4b3950772ef4deea49ed42094a5b4e54564875e/assets/fonts/gcc_currency.ttf).
  MIT, copyright 2026 ZIQX. SAR, AED and OMR shapes are third-party vector
  renditions of the official symbols, not fonts published by the central banks.
- `build/unifont-18.0.01.otf`: [GNU Unifont 18.0.01](https://www.unifoundry.com/pub/unifont/unifont-18.0.01/font-builds/unifont-18.0.01.otf).
  Used under SIL Open Font License 1.1; the distribution's copyright/license
  notices are preserved alongside the subset. Only the rufiyaa glyph is used.

Run `python tool/subset_currency_fonts.py`. The first font remaps source glyphs
E001/E002/E004 to 20C1/20C3/20C4; the second keeps only 20C2. Both derived font
families are renamed. Do not commit downloaded build inputs or fonttools.

The currency editor measures its selected label using its actual font and text
scale. It does not size by character count: `FCFA`, `soʻm`, and Arabic dotted
abbreviations can occupy different widths. On a narrow screen the price field
moves to the next line, preserving the whole currency label and touch target.

Physical-device acceptance: check these four glyphs on an older Android build,
both light/dark themes, and at enlarged text size. Imported/exported plain text
still depends on the receiving application's font coverage.
