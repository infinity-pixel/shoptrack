import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About ShopTrack')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ShopTrack',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Your Shopping Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Plan your shopping, track purchases and keep your history close—even offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  ListTile(
                    title: const Text('App Version'),
                    trailing: Text(
                      '1.0.0+1',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 40),
                  Text(
                    '© 2026 ShopTrack Team',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
