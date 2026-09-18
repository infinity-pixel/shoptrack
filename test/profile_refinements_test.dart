import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/data/sync_store.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/features/account/presentation/pages/cloud_sync_page.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/services/shopping_sync_service.dart';
import 'shopping_sync_test.dart' show MemoryRemote, session, milk;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalShoppingRepository.activeStore = null;
  });
  tearDown(() => LocalShoppingRepository.activeStore = null);

  for (final size in [
    const Size(320, 640),
    const Size(640, 360),
    const Size(800, 1000),
  ]) {
    testWidgets('Cloud Sync fits $size at 1.3 text scale', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final remote = MemoryRemote();
      final sync = ShoppingSyncService.testing(
        currentUid: () => null,
        identities: const Stream.empty(),
        remote: remote,
      );
      await sync.start();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.darkPresets.values.first.toThemeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: CloudSyncPage(service: sync),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Advanced Backup & Restore'),
        150,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Advanced Backup & Restore'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      sync.dispose();
      await remote.close();
    });
  }

  for (final definition in [
    ...ThemePresets.lightPresets.values,
    ...ThemePresets.darkPresets.values,
  ]) {
    testWidgets('Completion uses theme accent ${definition.name}', (
      tester,
    ) async {
      final completed = session([milk.copyWith(isPurchased: true)]);
      final store = SyncStore(await SharedPreferences.getInstance(), 'alice');
      await store.load(seed: [completed]);
      LocalShoppingRepository.activeStore = store;
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: definition.toThemeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: HomePage(sessionDate: completed.date),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Shopping Completed')).style!.color,
        definition.palette.primary,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Cloud Sync visual preview', (tester) async {
    await (FontLoader('LibreBaskerville')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville[wght].ttf')))
        .load();
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader('Ahem')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final remote = MemoryRemote();
    final sync = ShoppingSyncService.testing(
      currentUid: () => 'alice',
      identities: const Stream.empty(),
      remote: remote,
    );
    await sync.start();
    remote.emit('alice');
    await tester.pump();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemePresets.darkPresets.values.first.toThemeData(),
          home: CloudSyncPage(service: sync),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/cloud_sync_preview.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    sync.dispose();
    await remote.close();
  }, skip: font.isEmpty);
}
