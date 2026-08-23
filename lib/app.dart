import 'package:flutter/material.dart';
import 'core/data/settings_repository.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'services/settings_service.dart';

class ShopTrackApp extends StatefulWidget {
  const ShopTrackApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<ShopTrackApp> createState() => _ShopTrackAppState();

  static SettingsService of(BuildContext context) {
    return context.findAncestorStateOfType<_ShopTrackAppState>()!.settingsService;
  }
}

class _ShopTrackAppState extends State<ShopTrackApp> {
  late final SettingsService settingsService;

  @override
  void initState() {
    super.initState();
    settingsService = SettingsService(LocalSettingsRepository());
    settingsService.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, child) {
        return MaterialApp(
          title: 'ShopTrack',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: ShopTrackApp.scaffoldMessengerKey,
          themeMode: settingsService.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
          ),
          home: const MainPage(),
        );
      },
    );
  }
}
