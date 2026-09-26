"""Build-only: fonttools 4.66, inputs downloaded as documented in currency_symbols.md.

Only new currency glyphs are included; normal text keeps its existing font.
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path('build/font_tools').resolve()))
from fontTools.ttLib import TTFont
from fontTools import subset


def build(source, destination, family, mapping):
    font = TTFont(source)
    original = font.getBestCmap()
    for table in font['cmap'].tables:
        if table.isUnicode():
            for source_code, target_code in mapping.items():
                table.cmap[target_code] = original[source_code]
    options = subset.Options()
    options.name_IDs = ['*']
    sub = subset.Subsetter(options=options)
    sub.populate(unicodes=list(mapping.values()))
    sub.subset(font)
    for record in font['name'].names:
        if record.nameID in (1, 4, 6, 16):
            record.string = family.encode(record.getEncoding())
    font.save(destination)
    print(destination, sorted(hex(c) for c in font.getBestCmap()))


build('build/gcc_currency.ttf', 'assets/fonts/ShopTrackCurrency.ttf',
      'ShopTrackCurrency', {0xE001: 0x20C1, 0xE002: 0x20C3, 0xE004: 0x20C4})
build('build/unifont-18.0.01.otf', 'assets/fonts/ShopTrackRufiyaa.otf',
      'ShopTrackRufiyaa', {0x20C2: 0x20C2})
