import 'package:flutter/material.dart';

import 'features/home/presentation/pages/home_page.dart';

class ShopTrackApp extends StatelessWidget {
  const ShopTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}