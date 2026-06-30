import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShopTrack'),
      ),
      body: const Center(
        child: Text(
          "Today's Shopping",
        style: TextStyle(
        fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    );
  }
}