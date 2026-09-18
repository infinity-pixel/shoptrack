import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/models/auth_state.dart';
import 'package:shoptrack/models/cloud_backup_status.dart';
import 'package:shoptrack/services/auth_service.dart';
import 'package:shoptrack/services/cloud_backup_service.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';

class _Google extends Fake implements GoogleSignIn {
  int prompts = 0;
  int restores = 0;
  int initializations = 0;
  @override
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      const Stream.empty();
  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializations++;
  }

  @override
  Future<GoogleSignInAccount?> attemptLightweightAuthentication({
    bool reportAllExceptions = false,
  }) async {
    restores++;
    return null;
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    prompts++;
    return _Account();
  }

  @override
  Future<void> signOut() async {}
}

class _Account extends Fake implements GoogleSignInAccount {
  @override
  String get id => 'test';
  @override
  String get email => 'test@example.com';
  @override
  String? get displayName => 'Test';
  @override
  String? get photoUrl => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('History statuses fit a narrow phone with date options', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: Scaffold(
          body: SessionCard(
            session: ShoppingSession(
              id: 'narrow',
              date: DateTime(2026, 1, 1),
              items: const [
                ShoppingItem(
                  id: 'one',
                  name: 'Eggs',
                  isPurchased: true,
                  priceValue: 3092,
                ),
                ShoppingItem(id: 'two', name: 'Rice'),
              ],
            ),
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('1 Purchased'), findsOneWidget);
    expect(find.text('1 Pending'), findsOneWidget);
    expect(find.text('Total Purchased'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'Startup restores profile without any Google authentication prompt',
    () async {
      SharedPreferences.setMockInitialValues({
        GoogleAuthService.rememberedAccountKey: jsonEncode({
          'id': 'test',
          'email': 'test@example.com',
        }),
      });
      final google = _Google();
      final auth = GoogleAuthService(googleSignIn: google);
      final backup = GoogleDriveBackupService(
        googleSignIn: google,
        accountForCloudAction: auth.accountForCloudAction,
      );
      await auth.ready;
      expect(auth.state, isA<AuthRemembered>());
      expect(google.initializations, 1);
      expect(google.prompts, 0);
      expect(google.restores, 0);
      backup.updateSignInState(true);
      await backup.refreshStatus();
      expect(backup.status.state, CloudBackupState.available);
      expect(google.prompts, 0);
      await auth.accountForCloudAction();
      expect(google.prompts, 1);
      await auth.accountForCloudAction();
      expect(google.prompts, 1);
      await auth.signOut();
      expect(
        (await SharedPreferences.getInstance()).getString(
          GoogleAuthService.rememberedAccountKey,
        ),
        isNull,
      );
      backup.dispose();
      auth.dispose();
    },
  );

  testWidgets('FAB stays compact in height and reverses safely mid-motion', (
    tester,
  ) async {
    Future<void> show(bool expanded) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: DelayedExtendedFab(
            expanded: expanded,
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: 'Add Item',
          ),
        ),
      ),
    );
    await show(true);
    expect(tester.getSize(find.byType(DelayedExtendedFab)).height, 56);
    expect(tester.getSize(find.byIcon(Icons.add)), const Size(24, 24));
    final expandedWidth = tester.getSize(find.byType(DelayedExtendedFab)).width;
    await show(false);
    await tester.pump(const Duration(milliseconds: 120));
    await show(true);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(DelayedExtendedFab)).width,
      expandedWidth,
    );
    await show(false);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(DelayedExtendedFab)), const Size(56, 56));
    expect(tester.takeException(), isNull);
  });
}
