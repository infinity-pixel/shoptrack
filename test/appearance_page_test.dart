import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/settings_repository.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/features/account/presentation/pages/appearance_page.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/services/settings_service.dart';

void main() {
  Future<void> openAppearance(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = SettingsService(LocalSettingsRepository());
    addTearDown(service.dispose);
    await service.loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AppearancePage(settingsService: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Appearance is usable on a narrow screen with enlarged text', (
    tester,
  ) async {
    await openAppearance(tester, size: const Size(320, 640), textScale: 1.3);

    expect(find.text('Choose Theme'), findsOneWidget);
    expect(find.text('Blooming Spring'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Silent Midnight'), 220);
    await tester.pumpAndSettle();
    expect(find.text('Ancient Forest'), findsOneWidget);
    expect(find.text('Silent Midnight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appearance is usable on a short landscape display', (
    tester,
  ) async {
    await openAppearance(tester, size: const Size(640, 360));

    await tester.tap(find.byKey(const ValueKey('appearance-mode-dark')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ethereal Aurora'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ethereal Aurora'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Appearance visual preview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = SettingsService(LocalSettingsRepository());
    addTearDown(service.dispose);
    await service.loadSettings();
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
        home: RepaintBoundary(
          key: key,
          child: AppearancePage(settingsService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final previewContext = tester.element(find.byType(AppearancePage));
    await tester.runAsync(() async {
      for (final definition in [
        ...ThemePresets.lightPresets.values,
        ...ThemePresets.darkPresets.values,
      ]) {
        await precacheImage(
          AssetImage(definition.headerArtworkPath!),
          previewContext,
        );
      }
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/appearance_preview.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: font.isEmpty);
}
