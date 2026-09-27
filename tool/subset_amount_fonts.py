"""Build deterministic money text fonts; see docs/currency_symbols.md.

Usage: python tool/subset_amount_fonts.py <Flutter SDK>
Requires fonttools. Download the pinned Noto inputs into build/ first.
"""
from pathlib import Path
import sys
import shutil

sys.path.insert(0, str(Path('build/font_tools').resolve()))
from fontTools import subset
from fontTools.ttLib import TTFont

sdk_fonts = Path(sys.argv[1]) / 'bin/cache/artifacts/material_fonts'
output = Path('assets/fonts')


def build(source, family, weight, characters):
    font = TTFont(source)
    options = subset.Options()
    options.name_IDs = ['*']
    sub = subset.Subsetter(options=options)
    sub.populate(unicodes=characters)
    sub.subset(font)
    for record in font['name'].names:
        if record.nameID in (1, 16):
            record.string = family.encode(record.getEncoding())
        elif record.nameID in (4, 6):
            record.string = f'{family}-{weight}'.encode(record.getEncoding())
    font.save(output / f'{family}-{weight}.ttf')


for name, weight in [('regular', 400), ('medium', 500), ('bold', 700)]:
    # Latin letters, digits, punctuation and every currency sign in Roboto.
    # No ordinary Bengali or CJK text is replaced by these narrow subsets.
    build(sdk_fonts / f'roboto-{name}.ttf', 'ShopTrackAmounts', weight,
          [*range(0x20, 0x250), *range(0x20A0, 0x20C5)])
    build(Path('build') / f'NotoSansBengali-{name.title()}.ttf',
          'ShopTrackTaka', weight, [0x09F3])

shutil.copyfile(sdk_fonts / 'roboto_license.txt', output / 'ShopTrackAmounts-LICENSE.txt')
shutil.copyfile('build/NotoBengali-OFL.txt', output / 'ShopTrackTaka-OFL.txt')
