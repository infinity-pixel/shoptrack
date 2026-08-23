import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About ShopTrack'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'ShopTrack',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Your Shopping Companion',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text(
              'ShopTrack helps you manage your shopping sessions, track expenses, and plan for future purchases with ease. Whether you are at home or in the store, keep everything organized in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const ListTile(
              title: Text('App Version'),
              trailing: Text('1.0.0+1', style: TextStyle(color: Colors.grey)),
            ),
            const Divider(),
            const SizedBox(height: 40),
            Text(
              '© 2026 ShopTrack Team',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
