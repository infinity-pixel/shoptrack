import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/animation/rolling_digit.dart';
import 'package:shoptrack/core/theme/design_system.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/models/app_settings.dart';

void main() {
  group('Sprint 15.1: ShopTrack Design System & Theme Foundation', () {
    test('Light presets are available', () {
      expect(ThemePresets.lightPresets.length, 4);
      expect(ThemePresets.lightPresets.containsKey(LightPreset.summer), true);
      expect(ThemePresets.lightPresets.containsKey(LightPreset.spring), true);
      expect(ThemePresets.lightPresets.containsKey(LightPreset.ocean), true);
      expect(ThemePresets.lightPresets.containsKey(LightPreset.autumn), true);
    });

    test('Dark presets are available', () {
      expect(ThemePresets.darkPresets.length, 4);
      expect(ThemePresets.darkPresets.containsKey(DarkPreset.midnight), true);
      expect(ThemePresets.darkPresets.containsKey(DarkPreset.aurora), true);
      expect(ThemePresets.darkPresets.containsKey(DarkPreset.moonlit), true);
      expect(ThemePresets.darkPresets.containsKey(DarkPreset.deepForest), true);
    });

    test('AppSettings handles missing preset fields in fromJson', () {
      final json = {'theme': 'dark', 'currency': 'USD', 'language': 'Spanish'};
      final settings = AppSettings.fromJson(json);
      expect(settings.theme, AppTheme.dark);
      expect(settings.lightPreset, LightPreset.summer); // Default
      expect(settings.darkPreset, DarkPreset.midnight); // Default
      expect(settings.currency, 'USD');
      expect(settings.language, 'Spanish');
    });

    test('AppSettings serialization preserves presets', () {
      const settings = AppSettings(
        lightPreset: LightPreset.ocean,
        darkPreset: DarkPreset.aurora,
      );
      final json = settings.toJson();
      final decoded = AppSettings.fromJson(json);
      expect(decoded.lightPreset, LightPreset.ocean);
      expect(decoded.darkPreset, DarkPreset.aurora);
    });

    test('ShopTrackPalette.light provides semantic status colors', () {
      final palette = ShopTrackPalette.light(primary: Colors.blue);
      expect(palette.purchased, isA<Color>());
      expect(palette.pending, isA<Color>());
      expect(palette.planned, isA<Color>());
      expect(palette.today, isA<Color>());
    });

    test('ShopTrackTypography.standard provides necessary tokens', () {
      final typography = ShopTrackTypography.standard(Colors.black);
      expect(typography.screenTitle.fontSize, 28);
      expect(typography.price.fontWeight, FontWeight.bold);
      expect(
        typography.price.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('RollingDigitText updates only on value change', (
      WidgetTester tester,
    ) async {
      String text = '100.00';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingDigitText(text: text, style: const TextStyle()),
          ),
        ),
      );

      expect(find.byType(RollingDigit), findsAtLeastNWidgets(1));
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Rebuild with same text
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingDigitText(text: text, style: const TextStyle()),
          ),
        ),
      );
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Update text
      text = '150.00';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingDigitText(text: text, style: const TextStyle()),
          ),
        ),
      );

      // During transition
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    test('ThemePresets.getDefinition resolves correctly', () {
      const settings = AppSettings(
        theme: AppTheme.dark,
        darkPreset: DarkPreset.aurora,
      );
      final definition = ThemePresets.getDefinition(settings, Brightness.light);
      expect(definition.name, 'Aurora');
      expect(definition.brightness, Brightness.dark);
    });

    test('Summer preset supplies artwork and semantic list surfaces', () {
      final summer = ThemePresets.lightPresets[LightPreset.summer]!;

      expect(summer.headerArtworkPath, 'assets/images/theme_light_summer.webp');
      expect(summer.palette.surfaceToBuy, const Color(0xFFFFFDFA));
      expect(summer.palette.surfacePurchased, const Color(0xFFE8F6EA));
      expect(summer.palette.purchased, const Color(0xFF2E7D32));
    });

    test('Theme data exposes ShopTrack theme tokens', () {
      final theme = ThemePresets.lightPresets[LightPreset.summer]!
          .toThemeData();
      final tokens = theme.extension<ShopTrackThemeTokens>();

      expect(tokens, isNotNull);
      expect(
        tokens!.headerArtworkPath,
        'assets/images/theme_light_summer.webp',
      );
      expect(tokens.palette.border, const Color(0xFFF1E2C6));
    });

    testWidgets('Add Item uses keyboard next actions for name and quantity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddItemSheet(nextPosition: 0))),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].textInputAction, TextInputAction.next);
      expect(fields[1].textInputAction, TextInputAction.next);
    });

    testWidgets('Unit picker closes after choosing a unit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddItemSheet(nextPosition: 0))),
      );

      await tester.tap(find.byType(TextField).at(1));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(find.text('Kilogram (kg)'), findsOneWidget);
      await tester.tap(find.text('Kilogram (kg)'));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem), findsNothing);
      expect(find.text('Kilogram (kg)'), findsOneWidget);
    });
  });
}
