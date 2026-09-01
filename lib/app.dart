import 'package:flutter/material.dart';
import 'core/data/settings_repository.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'core/theme/theme_presets.dart';
import 'core/theme/atmospheric_background.dart';
import 'services/auth_service.dart';
import 'services/cloud_backup_service.dart';
import 'services/settings_service.dart';
import 'models/auth_state.dart';
import 'models/app_settings.dart';

class ShopTrackApp extends StatefulWidget {
  const ShopTrackApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<ShopTrackApp> createState() => _ShopTrackAppState();

  static SettingsService of(BuildContext context) {
    return context.findAncestorStateOfType<_ShopTrackAppState>()!.settingsService;
  }

  static AuthService authOf(BuildContext context) {
    return context.findAncestorStateOfType<_ShopTrackAppState>()!.authService;
  }

  static CloudBackupService cloudBackupOf(BuildContext context) {
    return context.findAncestorStateOfType<_ShopTrackAppState>()!.cloudBackupService;
  }
}

class _ShopTrackAppState extends State<ShopTrackApp> {
  late final SettingsService settingsService;
  late final AuthService authService;
  late final CloudBackupService cloudBackupService;

  @override
  void initState() {
    super.initState();
    settingsService = SettingsService(LocalSettingsRepository());
    settingsService.loadSettings();
    
    authService = GoogleAuthService(
      serverClientId: '1073842238529-h0oadkbch0vlhkp0469lkbbgk2vr8na0.apps.googleusercontent.com',
    );
    cloudBackupService = GoogleDriveBackupService();
    
    authService.addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    authService.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    final state = authService.state;
    if (cloudBackupService is GoogleDriveBackupService) {
      (cloudBackupService as GoogleDriveBackupService).updateSignInState(state is AuthAuthenticated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        final platformBrightness = MediaQuery.of(context).platformBrightness;
        final themeDefinition = ThemePresets.getDefinition(settingsService.settings, platformBrightness);

        return MaterialApp(
          title: 'ShopTrack',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: ShopTrackApp.scaffoldMessengerKey,
          themeMode: settingsService.themeMode,
          theme: ThemePresets.lightPresets[settingsService.settings.lightPreset]?.toThemeData() ??
              ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
          darkTheme: ThemePresets.darkPresets[settingsService.settings.darkPreset]?.toThemeData() ??
              ThemePresets.darkPresets[DarkPreset.midnight]!.toThemeData(),
          home: AtmosphericBackground(
            config: themeDefinition.atmosphericConfig,
            child: const MainPage(),
          ),
        );
      },
    );
  }
}
