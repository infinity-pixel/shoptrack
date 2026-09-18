import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/core/theme/atmospheric_background.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/shoptrack_navigation_bar.dart';
import 'package:shoptrack/features/history/presentation/pages/history_search_page.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/features/history/presentation/widgets/history_date_badge.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/features/home/presentation/widgets/record_hero.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_list_switcher.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';

final midnight = ThemePresets.darkPresets[DarkPreset.midnight]!;
final aurora = ThemePresets.darkPresets[DarkPreset.aurora]!;
final bleedingMoonlight = ThemePresets.darkPresets[DarkPreset.moonlit]!;
final ancientForest = ThemePresets.darkPresets[DarkPreset.deepForest]!;
final autumn = ThemePresets.lightPresets[LightPreset.autumn]!;
final ocean = ThemePresets.lightPresets[LightPreset.ocean]!;
final spring = ThemePresets.lightPresets[LightPreset.spring]!;
final summer = ThemePresets.lightPresets[LightPreset.summer]!;
const milk = ShoppingItem(
  id: 'milk',
  name: 'Milk',
  quantityValue: 2,
  shoppingUnit: ShoppingUnit.l,
  priceValue: 180,
  position: 0,
);
const rice = ShoppingItem(
  id: 'rice',
  name: 'Rice',
  quantityValue: 4.3,
  shoppingUnit: ShoppingUnit.kg,
  priceValue: 320,
  isPurchased: true,
  position: 1,
);

void seed() {
  final now = DateTime.now();
  SharedPreferences.setMockInitialValues({
    'app_settings': jsonEncode(
      const AppSettings(theme: AppTheme.dark).toJson(),
    ),
    'shopping_sessions': jsonEncode([
      ShoppingSession(
        id: 'today',
        date: DateTime(now.year, now.month, now.day),
        items: const [milk, rice],
      ).toJson(),
      ShoppingSession(
        id: 'past',
        date: DateTime(now.year, now.month, now.day - 3),
        items: const [rice],
      ).toJson(),
      ShoppingSession(
        id: 'future',
        date: DateTime(now.year, now.month, now.day + 3),
        items: const [milk],
      ).toJson(),
    ]),
  });
}

void main() {
  test('Ethereal Aurora has a complete, accessible dark identity', () {
    final p = aurora.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(
      aurora.headerArtworkPath,
      'assets/images/theme_dark_ethereal_aurora.webp',
    );
    expect(aurora.atmosphericConfig.baseColor, p.background);
    expect(p.background, isNot(midnight.palette.background));
    expect(p.primary, isNot(midnight.palette.primary));
    expect(p.receiptShadow, const Color(0x73000000));
    expect(aurora.navigationIconGradient, hasLength(3));
    expect(
      p.surface.computeLuminance(),
      greaterThan(p.background.computeLuminance()),
    );
    expect(
      p.surfaceToBuy.computeLuminance(),
      greaterThan(p.surface.computeLuminance()),
    );
    expect(
      p.surfacePurchased.computeLuminance(),
      greaterThan(p.surface.computeLuminance()),
    );

    for (final surface in [
      p.background,
      p.surface,
      p.surfacePurchased,
      p.surfaceReceipt,
      p.receiptEdge,
    ]) {
      for (final ink in [
        p.onSurface,
        p.textSecondary,
        p.purchased,
        p.purchasedStatus,
        p.pending,
        p.planned,
        p.today,
      ]) {
        expect(contrast(ink, surface), greaterThanOrEqualTo(4.5));
      }
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
  });

  testWidgets('Ethereal Aurora keeps a 96 percent center and black shadow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late LinearGradient backgroundGradient;

    await tester.pumpWidget(
      MaterialApp(
        theme: aurora.toThemeData(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              backgroundGradient = darkEdgeGradient(context);
              return AtmosphericBackground(
                config: aurora.atmosphericConfig,
                child: ShoppingListSwitcher(
                  lists: const [
                    ShoppingListGroup(id: 'one', name: 'Family', position: 0),
                    ShoppingListGroup(
                      id: 'two',
                      name: 'Grandmother',
                      position: 1,
                    ),
                    ShoppingListGroup(
                      id: 'three',
                      name: 'Weekend shopping',
                      position: 2,
                    ),
                  ],
                  activeListId: 'one',
                  itemCountForList: (_) => 0,
                  onSelected: (_) {},
                  onCreate: () {},
                  onManage: (_) {},
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(backgroundGradient.stops, const [0, .02, .98, 1]);
    expect(backgroundGradient.colors[1], aurora.palette.background);
    expect(backgroundGradient.colors[2], aurora.palette.background);
    final shadow = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('list-overflow-shadow')),
    );
    final shadowGradient = (shadow.decoration as BoxDecoration).gradient!;
    expect(
      tester.getSize(find.byKey(const ValueKey('list-overflow-shadow'))).width,
      12,
    );
    expect(shadowGradient.colors.last, Colors.black.withValues(alpha: .35));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Light themes use the shared narrow black list shadow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
        home: Scaffold(
          body: ShoppingListSwitcher(
            lists: const [
              ShoppingListGroup(id: 'one', name: 'Family', position: 0),
              ShoppingListGroup(
                id: 'two',
                name: 'Grandmother shopping',
                position: 1,
              ),
              ShoppingListGroup(
                id: 'three',
                name: 'Weekend shopping',
                position: 2,
              ),
            ],
            activeListId: 'one',
            itemCountForList: (_) => 0,
            onSelected: (_) {},
            onCreate: () {},
            onManage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shadow = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('list-overflow-shadow')),
    );
    final shadowGradient = (shadow.decoration as BoxDecoration).gradient!;
    expect(
      tester.getSize(find.byKey(const ValueKey('list-overflow-shadow'))).width,
      12,
    );
    expect(shadowGradient.colors.last, Colors.black.withValues(alpha: .12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ethereal Aurora and Blooming Spring gradient selected icons', (
    tester,
  ) async {
    Widget app(ThemeDefinition definition, int index) => MaterialApp(
      theme: definition.toThemeData(),
      home: Scaffold(
        bottomNavigationBar: ShopTrackNavigationBar(
          currentIndex: index,
          onTap: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(app(aurora, 0));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byIcon(Icons.list_alt_rounded),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byIcon(Icons.watch_later_outlined),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );

    await tester.pumpWidget(app(spring, 1));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byIcon(Icons.watch_later_rounded),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byIcon(Icons.list_alt_outlined),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );

    await tester.pumpWidget(app(midnight, 0));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byIcon(Icons.list_alt_rounded),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('Ember Autumn has a complete, accessible visual identity', () {
    final p = autumn.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(
      autumn.headerArtworkPath,
      'assets/images/theme_light_ember_autumn.webp',
    );
    expect(autumn.atmosphericConfig.baseColor, p.background);
    expect(autumn.atmosphericConfig.gradientColors, hasLength(3));
    expect(autumn.atmosphericConfig.opacity, greaterThan(0.3));
    expect(
      p.background,
      isNot(ThemePresets.lightPresets[LightPreset.summer]!.palette.background),
    );
    expect(
      p.primary,
      isNot(ThemePresets.lightPresets[LightPreset.summer]!.palette.primary),
    );

    for (final surface in [
      p.background,
      p.surface,
      p.surfacePurchased,
      p.surfaceReceipt,
    ]) {
      expect(contrast(p.onBackground, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.textSecondary, surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(
      contrast(p.purchasedStatus, p.surfacePurchased),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('Bleeding Moonlight has a complete, accessible dark identity', () {
    final p = bleedingMoonlight.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(bleedingMoonlight.name, 'Bleeding Moonlight');
    expect(
      bleedingMoonlight.headerArtworkPath,
      'assets/images/theme_dark_bleeding_moonlight.webp',
    );
    expect(bleedingMoonlight.atmosphericConfig.baseColor, p.background);
    expect(p.background, isNot(midnight.palette.background));
    expect(p.primary, isNot(midnight.palette.primary));
    expect(p.receiptShadow, const Color(0x80000000));
    expect(
      p.surface.computeLuminance(),
      greaterThan(p.background.computeLuminance()),
    );
    expect(
      p.surfaceToBuy.computeLuminance(),
      greaterThan(p.surface.computeLuminance()),
    );

    for (final surface in [
      p.background,
      p.surface,
      p.surfaceToBuy,
      p.surfacePurchased,
      p.surfaceReceipt,
      p.receiptEdge,
    ]) {
      for (final ink in [
        p.onSurface,
        p.textSecondary,
        p.purchased,
        p.purchasedStatus,
        p.pending,
        p.planned,
        p.today,
      ]) {
        expect(contrast(ink, surface), greaterThanOrEqualTo(4.5));
      }
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
  });

  test('Tranquil Ocean has a complete, accessible visual identity', () {
    final p = ocean.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(
      ocean.headerArtworkPath,
      'assets/images/theme_light_tranquil_ocean.webp',
    );
    expect(ocean.atmosphericConfig.baseColor, p.background);
    expect(ocean.atmosphericConfig.gradientColors, hasLength(3));
    expect(ocean.atmosphericConfig.opacity, greaterThanOrEqualTo(0.3));
    expect(
      p.background,
      isNot(ThemePresets.lightPresets[LightPreset.summer]!.palette.background),
    );
    expect(
      p.primary,
      isNot(ThemePresets.lightPresets[LightPreset.summer]!.palette.primary),
    );
    expect(
      p.background,
      isNot(ThemePresets.lightPresets[LightPreset.autumn]!.palette.background),
    );
    expect(
      p.surfaceToBuy.computeLuminance(),
      greaterThan(p.background.computeLuminance()),
    );

    for (final surface in [
      p.background,
      p.surface,
      p.surfaceToBuy,
      p.surfacePurchased,
      p.surfaceReceipt,
    ]) {
      expect(contrast(p.onBackground, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.textSecondary, surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
    expect(
      contrast(p.purchasedStatus, p.surfacePurchased),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('Blooming Spring has a complete accessible mixed-color identity', () {
    final p = spring.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(
      spring.headerArtworkPath,
      'assets/images/theme_light_blooming_spring.webp',
    );
    expect(spring.atmosphericConfig.baseColor, p.background);
    expect(spring.atmosphericConfig.gradientColors, hasLength(3));
    expect(spring.atmosphericConfig.opacity, greaterThanOrEqualTo(0.3));
    expect(spring.navigationIconGradient, hasLength(3));
    expect(spring.calendarAccent, const Color(0xFFB94F7A));
    expect(p.primary, isNot(p.secondary));
    expect(p.background, isNot(ocean.palette.background));
    expect(p.background, isNot(autumn.palette.background));
    expect(
      p.surfaceToBuy.computeLuminance(),
      greaterThan(p.background.computeLuminance()),
    );

    for (final surface in [
      p.background,
      p.surface,
      p.surfaceToBuy,
      p.surfacePurchased,
      p.surfaceReceipt,
    ]) {
      expect(contrast(p.onBackground, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.textSecondary, surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
    expect(
      contrast(p.purchasedStatus, p.surfacePurchased),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('Ancient Forest has a complete, accessible dark identity', () {
    final p = ancientForest.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    expect(ancientForest.name, 'Ancient Forest');
    expect(
      ancientForest.headerArtworkPath,
      'assets/images/theme_dark_ancient_forest.webp',
    );
    expect(ancientForest.atmosphericConfig.baseColor, p.background);
    expect(ancientForest.atmosphericConfig.gradientColors, hasLength(3));
    expect(ancientForest.atmosphericConfig.opacity, 1);
    expect(p.primary, isNot(aurora.palette.primary));
    expect(p.secondary, isNot(aurora.palette.secondary));
    expect(p.background, isNot(aurora.palette.background));
    expect(
      p.surfaceToBuy.computeLuminance(),
      greaterThan(p.background.computeLuminance()),
    );
    expect(p.receiptShadow, const Color(0x80000000));

    for (final surface in [
      p.background,
      p.surface,
      p.surfaceToBuy,
      p.surfacePurchased,
      p.surfaceReceipt,
    ]) {
      expect(contrast(p.onBackground, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.textSecondary, surface), greaterThanOrEqualTo(4.5));
    }
    for (final status in [p.purchased, p.pending, p.planned, p.today]) {
      expect(contrast(p.onStatus, status), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
    expect(
      contrast(p.purchasedStatus, p.surfacePurchased),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('Blooming Spring gives its calendar badge a blossom accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: spring.toThemeData(),
        home: Scaffold(body: HistoryDateBadge(date: DateTime(2026, 4, 12))),
      ),
    );

    final decorations = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(HistoryDateBadge),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(
      decorations.any(
        (decoration) => decoration.border?.top.color == spring.calendarAccent,
      ),
      isTrue,
    );
    expect(
      decorations.any(
        (decoration) => decoration.color == spring.calendarAccent,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final theme in [
    (
      name: 'Golden Summer',
      definition: summer,
      asset: 'assets/images/theme_light_golden_summer.webp',
    ),
    (
      name: 'Silent Midnight',
      definition: midnight,
      asset: 'assets/images/theme_dark_silent_midnight.webp',
    ),
    (
      name: 'Ethereal Aurora',
      definition: aurora,
      asset: 'assets/images/theme_dark_ethereal_aurora.webp',
    ),
    (
      name: 'Ember Autumn',
      definition: autumn,
      asset: 'assets/images/theme_light_ember_autumn.webp',
    ),
    (
      name: 'Tranquil Ocean',
      definition: ocean,
      asset: 'assets/images/theme_light_tranquil_ocean.webp',
    ),
    (
      name: 'Blooming Spring',
      definition: spring,
      asset: 'assets/images/theme_light_blooming_spring.webp',
    ),
    (
      name: 'Bleeding Moonlight',
      definition: bleedingMoonlight,
      asset: 'assets/images/theme_dark_bleeding_moonlight.webp',
    ),
    (
      name: 'Ancient Forest',
      definition: ancientForest,
      asset: 'assets/images/theme_dark_ancient_forest.webp',
    ),
  ]) {
    for (final size in [const Size(320, 640), const Size(640, 360)]) {
      testWidgets('${theme.name} scenery and background fit $size', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: theme.definition.toThemeData(),
            home: Scaffold(
              body: AtmosphericBackground(
                config: theme.definition.atmosphericConfig,
                child: Column(
                  children: [
                    RecordHero(date: DateTime(2026, 10, 17), onBack: () {}),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final artwork = tester.widget<Image>(find.byType(Image));
        expect((artwork.image as AssetImage).assetName, theme.asset);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('Midnight text and semantic colors contrast with their surfaces', () {
    final p = midnight.palette;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    for (final surface in [
      p.background,
      p.surface,
      p.surfacePurchased,
      p.surfaceReceipt,
      p.receiptEdge,
    ]) {
      for (final ink in [
        p.onSurface,
        p.textSecondary,
        p.purchased,
        p.purchasedStatus,
        p.pending,
        p.planned,
        p.today,
      ]) {
        expect(contrast(ink, surface), greaterThanOrEqualTo(4.5));
      }
    }
    expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
    expect(midnight.headerArtworkPath, endsWith('.webp'));
  });

  for (final theme in [
    (name: 'Silent Midnight', definition: midnight),
    (name: 'Ancient Forest', definition: ancientForest),
  ]) {
    for (final size in [
      const Size(320, 640),
      const Size(640, 360),
      const Size(800, 1000),
    ]) {
      testWidgets(
        '${theme.name} calendar and item drawer fit $size with keyboard',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          for (final child in <Widget>[
            SmartDateRangePicker(
              initialRange: DateTimeRange(
                start: DateTime(2026, 9, 7),
                end: DateTime(2026, 9, 13),
              ),
            ),
            const AddItemSheet(nextPosition: 2, initialItem: milk),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme.definition.toThemeData(),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(1.3),
                    viewInsets: EdgeInsets.only(bottom: size.height * .4),
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Align(
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (child is AddItemSheet) {
              await tester.ensureVisible(find.text('Save'));
              await tester.pumpAndSettle();
              expect(
                tester.getBottomRight(find.text('Save')).dy,
                lessThan(size.height * .6),
              );
            }
          }
        },
      );
    }
  }

  testWidgets(
    'Theme selection remains alphabetical and switching preserves settings',
    (tester) async {
      seed();
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      for (final entry in {
        'Dark Theme': [
          'Ancient Forest',
          'Bleeding Moonlight',
          'Ethereal Aurora',
          'Silent Midnight',
        ],
        'Light Theme': [
          'Blooming Spring',
          'Ember Autumn',
          'Golden Summer',
          'Tranquil Ocean',
        ],
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        final labels = tester
            .widgetList<RadioListTile<dynamic>>(
              find.byType(RadioListTile<DarkPreset>),
            )
            .map((t) => (t.title! as Text).data)
            .toList();
        if (entry.key == 'Dark Theme') expect(labels, entry.value);
        for (var i = 1; i < entry.value.length; i++) {
          expect(
            tester.getTopLeft(find.text(entry.value[i]).last).dy,
            greaterThan(
              tester.getTopLeft(find.text(entry.value[i - 1]).last).dy,
            ),
          );
        }
        await tester.tap(
          find
              .text(
                entry.key == 'Dark Theme'
                    ? 'Ethereal Aurora'
                    : 'Tranquil Ocean',
              )
              .last,
        );
        await tester.pumpAndSettle();
      }
      final saved =
          jsonDecode(
                (await SharedPreferences.getInstance()).getString(
                  'app_settings',
                )!,
              )
              as Map<String, dynamic>;
      expect(saved['darkPreset'], 'aurora');
      expect(saved['lightPreset'], 'ocean');
      expect(tester.takeException(), isNull);
    },
  );

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Render Silent Midnight actual screens', (tester) async {
    seed();
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    // Explicit TextStyles without a family use the test font, not Roboto.
    await (FontLoader('Ahem')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader('LibreBaskerville')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville[wght].ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    await tester.binding.setSurfaceSize(const Size(390, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/sprint_18_$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ShopTrackApp()),
    );
    await tester.pumpAndSettle();
    await capture('lists');
    await tester.tap(find.text('History').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await capture('history');
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await capture('profile');
    for (final entry in <String, Widget>{
      'search': const HistorySearchPage(),
      'calendar': Align(
        alignment: Alignment.bottomCenter,
        child: SmartDateRangePicker(
          initialRange: DateTimeRange(
            start: DateTime(2026, 9, 7),
            end: DateTime(2026, 9, 13),
          ),
        ),
      ),
      'drawer': const Align(
        alignment: Alignment.bottomCenter,
        child: AddItemSheet(nextPosition: 2, initialItem: milk),
      ),
      'record': Column(
        children: [RecordHero(date: DateTime(2026, 9, 5), onBack: () {})],
      ),
    }.entries) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: midnight.toThemeData(),
            home: Scaffold(body: entry.value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (entry.key == 'search') {
        await tester.enterText(find.byType(TextField).first, 'Rice');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }
      await capture(entry.key);
    }
    debugDisableShadows = true;
  }, skip: font.isEmpty);
}
