import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/widgets/lists_navigation_icon.dart';

void main() {
  testWidgets('vector Lists icon follows navigation size and theme color', (
    tester,
  ) async {
    const boundaryKey = ValueKey('icon');
    for (final color in [Colors.orange, Colors.green, Colors.white]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: IconTheme(
                data: IconThemeData(color: color, size: 28),
                child: const ListsNavigationIcon(),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ListsNavigationIcon)),
        const Size(28, 28),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ListsNavigationIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as ListsNavigationPainter).color, color);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(
          List.generate(
            bytes.lengthInBytes ~/ 4,
            (i) => bytes.getUint8(i * 4 + 3),
          ).any((alpha) => alpha > 0),
          isTrue,
        );
        image.dispose();
        final preview = await boundary.toImage(pixelRatio: 12);
        final png = await preview.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/lists_icon_preview.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        preview.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
