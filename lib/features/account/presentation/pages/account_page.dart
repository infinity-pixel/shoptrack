import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/currency/currency_catalog.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/widgets/currency_picker_dialog.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/auth_state.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/settings_service.dart';
import 'about_page.dart';
import 'appearance_page.dart';
import 'edit_profile_page.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/sign_out_dialog.dart';
import 'backup_restore_page.dart';
import 'cloud_sync_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = ShopTrackApp.of(context);
    final authService = ShopTrackApp.authOf(context);
    final profiles = ShopTrackApp.profileOf(context);
    final sync = ShopTrackApp.syncOf(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        settingsService,
        authService,
        profiles,
        ?sync,
      ]),
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
                            subtitle:
                                Theme.of(context).brightness == Brightness.dark
                                ? settings.darkPreset.displayName
                                : settings.lightPreset.displayName,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppearancePage(
                                  settingsService: settingsService,
                                ),
                              ),
                            ),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.payments_outlined,
                            title: 'Currency',
                            subtitle: _currencySubtitle(settings.currency),
                            onTap: () =>
                                _showCurrencyDialog(context, settingsService),
                          ),
                          _buildSettingsTile(
                            context,
                            icon: Icons.pin_outlined,
                            title: 'Number Format',
                            subtitle: settings.numberFormat.displayName,
                            onTap: () => _showNumberFormatDialog(
                              context,
                              settingsService,
                            ),
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
                    _buildSectionHeader(context, 'Account & Data'),
                    _surface(
                      context,
                      Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.cloud_upload_outlined,
                            title: sync == null ? 'Cloud Backup' : 'Cloud Sync',
                            subtitle:
                                sync?.statusLabel ??
                                (authState is AuthAuthenticated
                                    ? 'Back up to your Google account'
                                    : 'Sign in to enable cloud backup'),
                            onTap: () {
                              if (sync != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CloudSyncPage(service: sync),
                                  ),
                                );
                                return;
                              }
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
                          if (authState is AuthAuthenticated)
                            _buildSettingsTile(
                              context,
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Lists stay on this device',
                              onTap: () => confirmSignOut(context, authService),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _surface(
                      context,
                      Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.shopping_cart_outlined,
                            title: 'About ShopTrack',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            ),
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
            color: Colors.black.withValues(alpha: .035),
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
    final profiles = ShopTrackApp.profileOf(context);
    final local = account == null ? null : profiles.forAccount(account.id);
    final displayName = local?.name ?? account?.displayName ?? 'Your Profile';
    return _surface(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: account == null
                      ? CircleAvatar(
                          radius: 29,
                          backgroundColor: p.primary.withValues(alpha: .18),
                          child: Icon(
                            Icons.person_outline,
                            color: p.onSurface,
                            size: 29,
                          ),
                        )
                      : ProfileAvatar(
                          name: displayName,
                          radius: 29,
                          photo: local?.photo,
                          googlePhoto: local?.hideGooglePhoto == true
                              ? null
                              : account.photoUrl,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  account != null ? displayName : 'Welcome to ShopTrack',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
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
                if (profiles.loadError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Your saved profile could not be loaded. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.error),
                  ),
                ],
                if (account == null) ...[
                  const SizedBox(height: 10),
                  Divider(color: p.border),
                  Center(
                    child: state is AuthLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          )
                        : TextButton.icon(
                            onPressed: () => authService.signIn(),
                            icon: const Icon(Icons.login, size: 18),
                            label: Text(
                              errorMessage != null
                                  ? 'Retry Sign In'
                                  : 'Sign In With Google',
                            ),
                          ),
                  ),
                ],
              ],
            ),
            if (account != null)
              Positioned(
                top: -8,
                right: -6,
                child: TextButton.icon(
                  onPressed: !profiles.loaded || profiles.loadError != null
                      ? null
                      : () async {
                          await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                account: account,
                                profiles: profiles,
                                auth: authService,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
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

  String _currencySubtitle(String code) {
    final currency = CurrencyCatalog.resolve(code);
    return '${currency.code} · ${currency.name}';
  }

  Future<void> _showCurrencyDialog(
    BuildContext context,
    SettingsService settingsService,
  ) async {
    final settings = settingsService.settings;
    final selected = await showCurrencyPickerDialog(
      context,
      title: 'Default Currency',
      selectedCurrencyCode: settings.currency,
      defaultCurrencyCode: settings.currency,
      recentCurrencyCodes: settings.recentCurrencies,
    );
    if (!context.mounted || selected == null || selected == settings.currency) {
      return;
    }
    try {
      await settingsService.updateCurrency(selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default currency changed to $selected. Existing items were not changed.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the currency preference.'),
        ),
      );
    }
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

  Future<void> _showNumberFormatDialog(
    BuildContext context,
    SettingsService settingsService,
  ) async {
    final selected = await showDialog<NumberFormatPreference>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Number Format'),
        children: [
          for (final preference in NumberFormatPreference.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, preference),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preference.displayName),
                        Text(switch (preference) {
                          NumberFormatPreference.automatic =>
                            'Match each currency’s region',
                          NumberFormatPreference.international =>
                            '1,234,567 · 1.23M',
                          NumberFormatPreference.southAsian =>
                            '12,34,567 · 12.34 Lakh',
                        }, style: Theme.of(dialogContext).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (settingsService.settings.numberFormat == preference)
                    const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    await settingsService.updateNumberFormat(selected);
  }
}
