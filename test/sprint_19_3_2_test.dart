import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/date_parts_field.dart';
import 'package:shoptrack/features/account/presentation/pages/cloud_sync_page.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/services/firestore_sync_remote.dart';
import 'package:shoptrack/services/shopping_sync_service.dart';

// The UI-only service is never started and must not access any remote data.
class _UnusedRemote implements SyncRemote {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child, {bool dark = false, double scale = 1.3}) =>
    MaterialApp(
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('en', 'US'), Locale('bn', 'BD')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme:
          (dark
                  ? ThemePresets.darkPresets.values.first
                  : ThemePresets.lightPresets.values.first)
              .toThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  setUp(() {
    Intl.defaultLocale = 'bn_BD';
  });
  tearDown(() {
    Intl.defaultLocale = null;
  });

  testWidgets('Bangla date fields accept either keyboard numeral style', (
    tester,
  ) async {
    DateTime? changed;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: DatePartsField(
            date: DateTime(2026, 9, 26),
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('২০২৬'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '25');
    expect(changed, DateTime(2026, 9, 25));
    expect(find.text('২৫'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '২৪');
    expect(changed, DateTime(2026, 9, 24));
  });

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    for (final dark in [false, true]) {
      testWidgets('Bangla sync and calendar fit $size dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = ShoppingSyncService.testing(
          currentUid: () => null,
          identities: const Stream.empty(),
          remote: _UnusedRemote(),
        );
        await tester.pumpWidget(
          _app(CloudSyncPage(service: service), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text('এই ডিভাইসে সংরক্ষিত'), findsOneWidget);
        expect(find.text('Settings kept on this device'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SmartDateRangePicker(
                initialRange: DateTimeRange(
                  start: DateTime(2026, 9, 8),
                  end: DateTime(2026, 9, 26),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('শুরুর তারিখ'), findsOneWidget);
        expect(find.text('শেষের তারিখ'), findsOneWidget);
        expect(find.text('রবি'), findsOneWidget);
        expect(find.text('আগের ৭ দিন'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
      });
    }
  }

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Bangla visual preview', (tester) async {
    for (final family in ['Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = ShoppingSyncService.testing(
      currentUid: () => null,
      identities: const Stream.empty(),
      remote: _UnusedRemote(),
    );
    for (final entry in <String, Widget>{
      'sync': CloudSyncPage(service: service),
      'calendar': Scaffold(
        body: SmartDateRangePicker(
          initialRange: DateTimeRange(
            start: DateTime(2026, 9, 8),
            end: DateTime(2026, 9, 26),
          ),
        ),
      ),
    }.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: _app(entry.value, dark: true, scale: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/sprint_19_3_2_${entry.key}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  }, skip: font.isEmpty);
}
