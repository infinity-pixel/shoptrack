import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/theme/theme_presets.dart';
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

    return ListenableBuilder(
      listenable: Listenable.merge([settingsService, authService]),
      builder: (context, _) {
        final authState = authService.state;
        final settings = settingsService.settings;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Profile',
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
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _buildProfileTile(context, authService, authState),
                    _buildSectionHeader(context, 'Preferences'),
                    _surface(
                      context,
                      Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: settings.theme.displayName,
                            onTap: () =>
                                _showAppearanceDialog(context, settingsService),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.light_mode_outlined,
                            title: 'Light Theme',
                            subtitle: settings.lightPreset.displayName,
                            onTap: () => _showLightPresetDialog(
                              context,
                              settingsService,
                            ),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Theme',
                            subtitle: settings.darkPreset.displayName,
                            onTap: () =>
                                _showDarkPresetDialog(context, settingsService),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.payments_outlined,
                            title: 'Currency',
                            subtitle: settings.currency,
                            onTap: () => _showCurrencyDialog(context),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.translate_outlined,
                            title: 'Language',
                            subtitle: settings.language,
                            onTap: () => _showLanguageDialog(context),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader(context, 'Data & Backup'),
                    _surface(
                      context,
                      Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.cloud_upload_outlined,
                            title: 'Cloud Backup',
                            subtitle: authState is AuthAuthenticated
                                ? 'Back up to your Google account'
                                : 'Sign in to enable cloud backup',
                            onTap: () {
                              if (authState is AuthAuthenticated) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BackupRestorePage(initialTab: 1),
                                  ),
                                );
                              } else {
                                _showSignInRequiredDialog(context, authService);
                              }
                            },
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.settings_backup_restore_outlined,
                            title: 'Backup & Restore',
                            subtitle: 'Export or import your local data',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BackupRestorePage(initialTab: 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader(context, 'About'),
                    _surface(
                      context,
                      Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.info_outline,
                            title: 'About ShopTrack',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            ),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.verified_outlined,
                            title: 'App Version',
                            subtitle: '1.0.0+1',
                          ),
                        ],
                      ),
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

  Widget _surface(BuildContext context, Widget child) {
    final p = ShopTrackThemeTokens.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: p.onBackground.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: child is Column
            ? Column(
                children: [
                  for (int i = 0; i < child.children.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, thickness: 1, color: p.border),
                    child.children[i],
                  ],
                ],
              )
            : child,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final p = ShopTrackThemeTokens.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: p.onBackground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: p.border)),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    AuthService authService,
    AuthState state,
  ) {
    final p = ShopTrackThemeTokens.of(context).palette;
    final account = state is AuthAuthenticated ? state.account : null;
    final errorMessage = state is AuthError ? state.message : null;
    return _surface(
      context,
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor: p.primary.withValues(alpha: .18),
                foregroundColor: p.onSurface,
                foregroundImage: account?.photoUrl == null
                    ? null
                    : NetworkImage(account!.photoUrl!),
                onForegroundImageError: account?.photoUrl == null
                    ? null
                    : (_, _) {},
                child: account != null
                    ? Text(
                        (account.displayName?.trim().isNotEmpty == true
                                ? account.displayName!.trim()
                                : account.email)
                            .characters
                            .first
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: p.onSurface,
                            ),
                      )
                    : const Icon(Icons.person_outline, size: 34),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                account?.displayName ??
                    (account != null ? 'Your Profile' : 'Welcome to ShopTrack'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: p.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (account != null)
              Tooltip(
                message: account.email,
                child: Text(
                  account.email,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: p.textSecondary),
                ),
              )
            else
              Text(
                errorMessage ?? 'Sign in with Google to use cloud backup.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: errorMessage != null ? p.error : p.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Divider(color: p.border),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: state is AuthLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Signing In',
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () {
                        account != null
                            ? authService.signOut()
                            : authService.signIn();
                      },
                      style: TextButton.styleFrom(foregroundColor: p.onSurface),
                      icon: Icon(
                        account != null ? Icons.logout : Icons.login,
                        size: 18,
                      ),
                      label: Text(
                        account != null
                            ? 'Sign Out'
                            : errorMessage != null
                            ? 'Retry Sign In'
                            : 'Sign In With Google',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignInRequiredDialog(
    BuildContext context,
    AuthService authService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'You need to sign in with your Google account to use cloud backup and synchronization features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final p = ShopTrackThemeTokens.of(context).palette;
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      minLeadingWidth: 36,
      horizontalTitleGap: 12,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 21, color: p.onSurface),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: p.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: p.textSecondary),
            ),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right, size: 20, color: p.textSecondary),
      onTap: onTap,
    );
  }

  void _showAppearanceDialog(BuildContext context, SettingsService service) {
    _choose<AppTheme>(
      context,
      'Choose Appearance',
      AppTheme.values,
      service.settings.theme,
      (v) => v.displayName,
      (v) {
        service.updateTheme(v);
      },
    );
  }

  void _showLightPresetDialog(BuildContext context, SettingsService service) {
    _choose<LightPreset>(
      context,
      'Light Theme Preset',
      LightPreset.values,
      service.settings.lightPreset,
      (v) => v.displayName,
      (v) {
        service.updateLightPreset(v);
      },
    );
  }

  void _showDarkPresetDialog(BuildContext context, SettingsService service) {
    _choose<DarkPreset>(
      context,
      'Dark Theme Preset',
      DarkPreset.values,
      service.settings.darkPreset,
      (v) => v.displayName,
      (v) {
        service.updateDarkPreset(v);
      },
    );
  }

  void _choose<T>(
    BuildContext context,
    String title,
    List<T> values,
    T selected,
    String Function(T) label,
    void Function(T) onSelected,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        scrollable: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: RadioGroup<T>(
          groupValue: selected,
          onChanged: (value) {
            if (value == null) return;
            Navigator.pop(dialogContext);
            onSelected(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in values)
                RadioListTile<T>(title: Text(label(value)), value: value),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency Preference'),
        content: const Text(
          'Bangladeshi Taka (৳) is the default currency. Additional currency options will be added in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Preference'),
        content: const Text(
          'English is currently the supported language. More languages will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
