import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/auth_state.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/settings_service.dart';
import 'about_page.dart';
import 'backup_restore_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = ShopTrackApp.of(context);
    final authService = ShopTrackApp.authOf(context);
    final settings = settingsService.settings;

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final authState = authService.state;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account & Settings'),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader('ACCOUNT'),
              _buildProfileTile(context, authService, authState),
              const SizedBox(height: 16),
              
              _buildSectionHeader('PREFERENCES'),
              _buildSettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: settings.theme.displayName,
                onTap: () => _showAppearanceDialog(context, settingsService),
              ),
              _buildSettingsTile(
                icon: Icons.payments_outlined,
                title: 'Currency',
                subtitle: settings.currency,
                onTap: () => _showCurrencyDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.translate_outlined,
                title: 'Language',
                subtitle: settings.language,
                onTap: () => _showLanguageDialog(context),
              ),
              const SizedBox(height: 16),
              
              _buildSectionHeader('DATA'),
              _buildSettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Cloud Backup',
                subtitle: authState is AuthAuthenticated 
                    ? 'Sync your data securely' 
                    : 'Sign in to enable cloud backup',
                onTap: () {
                  if (authState is AuthAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BackupRestorePage(initialTab: 1)),
                    );
                  } else {
                    _showSignInRequiredDialog(context, authService);
                  }
                },
              ),
              _buildSettingsTile(
                icon: Icons.settings_backup_restore_outlined,
                title: 'Backup & Restore',
                subtitle: 'Export or import your local data',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackupRestorePage(initialTab: 0)),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSectionHeader('ABOUT'),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About ShopTrack',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.code, color: Colors.transparent),
                title: Text('App Version'),
                trailing: Text('1.0.0+1', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 80), // Clearance for BottomNavigationBar
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, AuthService authService, AuthState state) {
    if (state is AuthError) {
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[50],
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            title: const Text('Sign-in Error'),
            subtitle: Text(state.message, style: const TextStyle(color: Colors.red)),
            trailing: TextButton(
              onPressed: () => authService.signIn(),
              child: const Text('Retry'),
            ),
          ),
          const Divider(),
        ],
      );
    }

    if (state is AuthAuthenticated) {
      final account = state.account;
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: account.photoUrl != null ? NetworkImage(account.photoUrl!) : null,
          backgroundColor: Colors.blue[100],
          child: account.photoUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
        ),
        title: Text(account.displayName ?? account.email),
        subtitle: Text(account.email),
        trailing: TextButton(
          onPressed: () => authService.signOut(),
          child: const Text('Sign Out'),
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.person, color: Colors.grey),
      ),
      title: const Text('Not signed in'),
      subtitle: const Text('Sign in for cloud backup & sync'),
      trailing: state is AuthLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right, size: 20),
      onTap: state is AuthLoading ? null : () => authService.signIn(),
    );
  }

  void _showSignInRequiredDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('You need to sign in with your Google account to use cloud backup and synchronization features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authService.signIn();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showAppearanceDialog(BuildContext context, SettingsService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            return RadioListTile<AppTheme>(
              title: Text(theme.displayName),
              value: theme,
              // ignore: deprecated_member_use
              groupValue: service.settings.theme,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  service.updateTheme(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency Preference'),
        content: const Text('Bangladeshi Taka (৳) is the default currency. Additional currency options will be added in a future update.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Preference'),
        content: const Text('English is currently the supported language. More languages will be available soon.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
