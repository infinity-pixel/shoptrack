import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/shopping_sync_service.dart';
import 'services/firestore_sync_remote.dart';
import 'core/data/settings_repository.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'core/theme/theme_presets.dart';
import 'core/theme/atmospheric_background.dart';
import 'services/auth_service.dart';
import 'services/cloud_backup_service.dart';
import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'models/auth_state.dart';
import 'models/app_settings.dart';

class ShopTrackApp extends StatefulWidget {
  const ShopTrackApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<ShopTrackApp> createState() => _ShopTrackAppState();

  static SettingsService of(BuildContext context) {
    return context
        .findAncestorStateOfType<_ShopTrackAppState>()!
        .settingsService;
  }

  static AuthService authOf(BuildContext context) {
    return context.findAncestorStateOfType<_ShopTrackAppState>()!.authService;
  }

  static ProfileService profileOf(BuildContext context) {
    return context
        .findAncestorStateOfType<_ShopTrackAppState>()!
        .profileService;
  }

  static CloudBackupService cloudBackupOf(BuildContext context) {
    return context
        .findAncestorStateOfType<_ShopTrackAppState>()!
        .cloudBackupService;
  }

  static ShoppingSyncService? syncOf(BuildContext context) =>
      context.findAncestorStateOfType<_ShopTrackAppState>()?.syncService;
}

class _ShopTrackAppState extends State<ShopTrackApp> {
  late final SettingsService settingsService;
  late final ProfileService profileService;
  late final AuthService authService;
  late final CloudBackupService cloudBackupService;
  ShoppingSyncService? syncService;

  @override
  void initState() {
    super.initState();
    profileService = ProfileService();
    settingsService = SettingsService(LocalSettingsRepository());
    settingsService.loadSettings();

    authService = GoogleAuthService(
      // This is the Web OAuth client generated in google-services.json.
      // It exchanges the Android Google token for a Firebase identity.
      serverClientId:
          '1073842238529-g0ii3oki3rguq3p69vutgp6vhc4kjje3.apps.googleusercontent.com',
      // Widget tests build the app without calling main(), so Firebase has not
      // been initialized there. Production reaches this point only after main
      // initializes Firebase.
      firebaseAuth: Firebase.apps.isEmpty
          ? null
          : firebase_auth.FirebaseAuth.instance,
    );
    cloudBackupService = GoogleDriveBackupService(
      accountForCloudAction:
          (authService as GoogleAuthService).accountForCloudAction,
    );

    authService.addListener(_handleAuthChange);
    if (Firebase.apps.isNotEmpty) {
      syncService = ShoppingSyncService(
        auth: firebase_auth.FirebaseAuth.instance,
        remote: FirestoreSyncRemote(FirebaseFirestore.instance),
      );
      syncService!.start();
    }
  }

  @override
  void dispose() {
    syncService?.dispose();
    authService.removeListener(_handleAuthChange);
    cloudBackupService.dispose();
    authService.dispose();
    settingsService.dispose();
    profileService.dispose();
    super.dispose();
  }

  void _handleAuthChange() {
    final state = authService.state;
    if (state is AuthLoading) return;
    if (cloudBackupService is GoogleDriveBackupService) {
      (cloudBackupService as GoogleDriveBackupService).updateSignInState(
        state is AuthAuthenticated,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settingsService, ?syncService]),
      builder: (context, child) {
        final platformBrightness = MediaQuery.of(context).platformBrightness;
        final themeDefinition = ThemePresets.getDefinition(
          settingsService.settings,
          platformBrightness,
        );

        return MaterialApp(
          key: ValueKey(syncService?.store?.scope ?? 'local'),
          title: 'ShopTrack',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: ShopTrackApp.scaffoldMessengerKey,
          themeMode: settingsService.themeMode,
          theme:
              ThemePresets.lightPresets[settingsService.settings.lightPreset]
                  ?.toThemeData() ??
              ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
          darkTheme:
              ThemePresets.darkPresets[settingsService.settings.darkPreset]
                  ?.toThemeData() ??
              ThemePresets.darkPresets[DarkPreset.midnight]!.toThemeData(),
          home:
              syncService != null &&
                  (!syncService!.ready || syncService!.switching)
              ? Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: syncService!.error == null
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_outlined, size: 42),
                                const SizedBox(height: 12),
                                Text(
                                  syncService!.error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: syncService!.retry,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                    ),
                  ),
                )
              : AtmosphericBackground(
                  config: themeDefinition.atmosphericConfig,
                  child: const MainPage(),
                ),
        );
      },
    );
  }
}
