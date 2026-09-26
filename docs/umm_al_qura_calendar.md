# Umm al-Qura calendar provenance

ShopTrack stores shopping days as Gregorian civil dates. Its optional Hijri view
uses a bundled lookup derived from Unicode ICU 75.1's `islamic-umalqura` calendar,
through Node 20.17.0 `Intl.DateTimeFormat`. The lookup covers AH 1300–1600; the
application's selectable Gregorian interval (2000–2100) and all five correction
settings remain inside that table. No extrapolated Islamic civil dates, network
requests, geographical assumptions or prayer-time calculations are used.

`tool/generate_umm_al_qura.mjs` prints the reproducible year masks. Each bit records
whether one lunar month has 30 rather than 29 days. The epoch is 1 Muharram 1300,
12 November 1882 Gregorian. Forward conversion adds the user's correction to the
civil day; inverse conversion subtracts it, using UTC day arithmetic internally
to avoid daylight-saving errors. Returning to local `DateTime` preserves the
original civil year/month/day, not a shifted UTC instant.

References:

- https://github.com/unicode-org/icu/blob/main/icu4j/main/core/src/main/java/com/ibm/icu/util/IslamicCalendar.java
- https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/IslamicCalendar.html
- https://pub.dev/packages/hijri/versions/3.0.1 (independent published conversion fixtures)
- https://pub.dev/packages/hijri_plus (independent 1446 month-start fixtures)

The method is an explicit calendar convention, not a claim about local moon
sightings or religious announcements. A manual offset may need updating when
local announcements differ in a later month.

## Unicode/ICU data notice

UNICODE LICENSE V3

COPYRIGHT AND PERMISSION NOTICE

Copyright © 2016-2024 Unicode, Inc.

NOTICE TO USER: Carefully read the following legal agreement. BY
DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.
Permission is hereby granted, free of charge, to any person obtaining a
copy of data files and any associated documentation (the "Data Files") or
software and any associated documentation (the "Software") to deal in the
Data Files or Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, and/or sell
copies of the Data Files or Software, and to permit persons to whom the
Data Files or Software are furnished to do so, provided that either (a)
this copyright and permission notice appear with all copies of the Data
Files or Software, or (b) this copyright and permission notice appear in
associated Documentation.
THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
THIRD PARTY RIGHTS.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE
BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA
FILES OR SOFTWARE.
Except as contained in this notice, the name of a copyright holder shall
not be used in advertising or otherwise to promote the sale, use or other
dealings in these Data Files or Software without prior written
authorization of the copyright holder.

SPDX-License-Identifier: Unicode-3.0
