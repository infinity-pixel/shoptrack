import 'package:flutter/material.dart';
import 'features/main/presentation/pages/main_page.dart';

class ShopTrackApp extends StatelessWidget {
  const ShopTrackApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopTrack',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}
