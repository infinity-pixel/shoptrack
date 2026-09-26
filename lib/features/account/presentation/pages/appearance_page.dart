import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../models/app_settings.dart';
import '../../../../services/settings_service.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        final settings = settingsService.settings;
        final lightPresets = [...LightPreset.values]
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        final darkPresets = [...DarkPreset.values]
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        return Scaffold(
          appBar: AppBar(
            title: ShopText(
              'Appearance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _SectionHeader(
                      title: 'Choose Theme',
                      description:
                          'Use your device setting or keep ShopTrack in light or dark mode.',
                    ),
                    _ModeSelector(
                      selected: settings.theme,
                      onSelected: settingsService.updateTheme,
                    ),
                    const SizedBox(height: 26),
                    const _SectionHeader(
                      title: 'Light Theme',
                      description: 'Choose the scenery used in light mode.',
                    ),
                    _PresetGrid<LightPreset>(
                      values: lightPresets,
                      selected: settings.lightPreset,
                      definitionFor: (preset) =>
                          ThemePresets.lightPresets[preset]!,
                      onSelected: settingsService.updateLightPreset,
                    ),
                    const SizedBox(height: 26),
                    const _SectionHeader(
                      title: 'Dark Theme',
                      description: 'Choose the scenery used in dark mode.',
                    ),
                    _PresetGrid<DarkPreset>(
                      values: darkPresets,
                      selected: settings.darkPreset,
                      definitionFor: (preset) =>
                          ThemePresets.darkPresets[preset]!,
                      onSelected: settingsService.updateDarkPreset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShopText(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.onBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          ShopText(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onSelected});

  final AppTheme selected;
  final Future<void> Function(AppTheme) onSelected;

  static const _icons = {
    AppTheme.system: Icons.brightness_auto_outlined,
    AppTheme.light: Icons.light_mode_outlined,
    AppTheme.dark: Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final children = AppTheme.values.map((mode) {
          final isSelected = mode == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: '${mode.displayName} appearance',
            child: Material(
              color: isSelected
                  ? Color.alphaBlend(
                      palette.primary.withValues(alpha: .14),
                      palette.surface,
                    )
                  : palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? palette.primary : palette.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('appearance-mode-${mode.name}'),
                onTap: isSelected ? null : () => onSelected(mode),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 8,
                    vertical: 13,
                  ),
                  child: compact
                      ? Row(
                          children: [
                            Icon(
                              _icons[mode],
                              size: 21,
                              color: palette.onSurface,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ShopText(
                                mode.displayName,
                                style: _modeTextStyle(
                                  context,
                                  palette,
                                  isSelected,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                size: 19,
                                color: palette.primary,
                              ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icons[mode],
                              size: 22,
                              color: palette.onSurface,
                            ),
                            const SizedBox(height: 7),
                            ShopText(
                              mode.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _modeTextStyle(
                                context,
                                palette,
                                isSelected,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        }).toList();

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }

  TextStyle? _modeTextStyle(
    BuildContext context,
    ShopTrackPalette palette,
    bool isSelected,
  ) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
      color: palette.onSurface,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
    );
  }
}

class _PresetGrid<T> extends StatelessWidget {
  const _PresetGrid({
    required this.values,
    required this.selected,
    required this.definitionFor,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final ThemeDefinition Function(T) definitionFor;
  final Future<void> Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final value in values)
              SizedBox(
                width: width,
                child: _PresetCard<T>(
                  value: value,
                  definition: definitionFor(value),
                  selected: value == selected,
                  onSelected: onSelected,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresetCard<T> extends StatelessWidget {
  const _PresetCard({
    required this.value,
    required this.definition,
    required this.selected,
    required this.onSelected,
  });

  final T value;
  final ThemeDefinition definition;
  final bool selected;
  final Future<void> Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final currentPalette = ShopTrackThemeTokens.of(context).palette;
    final previewPalette = definition.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: '${definition.name} theme',
      child: Material(
        color: currentPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? currentPalette.primary : currentPalette.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('appearance-preset-${definition.name}'),
          onTap: selected ? null : () => onSelected(value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: previewPalette.background),
                    if (definition.headerArtworkPath != null)
                      Image.asset(
                        definition.headerArtworkPath!,
                        fit: BoxFit.cover,
                        matchTextDirection: true,
                        alignment: Alignment.topCenter,
                      ),
                    PositionedDirectional(
                      end: 7,
                      top: 7,
                      child: AnimatedScale(
                        scale: selected ? 1 : .8,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: previewPalette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: previewPalette.onPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: previewPalette.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: previewPalette.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentPalette.border,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: ShopText(
                        definition.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: currentPalette.onSurface,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
