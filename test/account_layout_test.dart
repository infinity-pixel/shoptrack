import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/features/account/presentation/pages/account_page.dart';
import 'package:shoptrack/features/account/presentation/pages/appearance_page.dart';
import 'package:shoptrack/models/app_settings.dart';

void main() {
  testWidgets(
    'Account remains scrollable on small displays and theme selection works',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Sign In With Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('Choose Theme'), findsOneWidget);
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AppearancePage));
      expect(ShopTrackApp.of(context).settings.theme, AppTheme.dark);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byType(AccountPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Cloud Backup'),
        180,
        scrollable: scroll,
      );
      await tester.drag(scroll, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cloud Backup'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('About ShopTrack'),
        180,
        scrollable: scroll,
      );
      expect(tester.takeException(), isNull);
    },
  );

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Account visual preview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ShopTrackApp()),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/account_preview.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: font.isEmpty);
}
