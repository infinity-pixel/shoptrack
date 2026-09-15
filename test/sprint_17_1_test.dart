import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/features/account/presentation/pages/edit_profile_page.dart';
import 'package:shoptrack/features/account/presentation/widgets/sign_out_dialog.dart';
import 'package:shoptrack/models/auth_state.dart';
import 'package:shoptrack/services/auth_service.dart';
import 'package:shoptrack/services/profile_service.dart';

const account = AuthAccount(
  id: 'one',
  email: 'ishtiak@example.com',
  displayName: 'Ishtiak',
);

class Auth extends AuthService {
  AuthState current = const AuthRemembered(account);
  bool fail = false;
  int signOuts = 0;
  @override
  AuthState get state => current;
  @override
  Future<void> signIn() async {}
  @override
  Future<void> signOut() async {
    signOuts++;
    if (fail) throw StateError('offline');
    current = const AuthUnauthenticated();
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Profile persists per account and removal overrides the Google photo',
    () async {
      final service = ProfileService();
      await service.ready;
      await service.save(
        'one',
        LocalProfile(name: 'My Name', photo: Uint8List.fromList([1, 2, 3])),
      );
      await service.save('two', const LocalProfile(name: 'Another Name'));
      final reloaded = ProfileService();
      await reloaded.ready;
      expect(reloaded.forAccount('one')!.photo, [1, 2, 3]);
      expect(reloaded.forAccount('two')!.name, 'Another Name');
      await reloaded.save(
        'one',
        const LocalProfile(name: 'My Name', hideGooglePhoto: true),
      );
      final removed = ProfileService();
      await removed.ready;
      expect(removed.forAccount('one')!.photo, isNull);
      expect(removed.forAccount('one')!.hideGooglePhoto, isTrue);
      expect(removed.forAccount('two')!.name, 'Another Name');
      service.dispose();
      reloaded.dispose();
      removed.dispose();
    },
  );

  Future<void> openEditor(
    WidgetTester tester,
    ProfileService profiles,
    Auth auth,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    account: account,
                    profiles: profiles,
                    auth: auth,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Save persists, Cancel discards, and account change blocks saving',
    (tester) async {
      final profiles = ProfileService();
      await profiles.ready;
      final auth = Auth();
      await openEditor(tester, profiles, auth);
      await tester.enterText(find.byType(TextFormField), 'Local Name');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(profiles.forAccount('one')!.name, 'Local Name');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Local Name'), findsWidgets);
      await tester.enterText(find.byType(TextFormField), 'Unsaved');
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(profiles.forAccount('one')!.name, 'Local Name');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      auth.current = const AuthUnauthenticated();
      await tester.enterText(find.byType(TextFormField), 'Blocked');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your account changed'), findsOneWidget);
      expect(profiles.forAccount('one')!.name, 'Local Name');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      profiles.dispose();
      auth.dispose();
    },
  );

  testWidgets(
    'Editor supports small screen with keyboard and validates empty names',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final profiles = ProfileService();
      await profiles.ready;
      final auth = Auth();
      await openEditor(tester, profiles, auth);
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(find.byType(TextFormField), '');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a name.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      profiles.dispose();
      auth.dispose();
    },
  );

  testWidgets(
    'Sign out cancellation and failure preserve state; retry closes dialog',
    (tester) async {
      final auth = Auth();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => confirmSignOut(context, auth),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('remain accessible'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 0);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      auth.fail = true;
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not sign out'), findsOneWidget);
      expect(auth.state, isA<AuthAuthenticated>());
      auth.fail = false;
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out?'), findsNothing);
      expect(auth.state, isA<AuthUnauthenticated>());
      auth.dispose();
    },
  );

  testWidgets('Photo is resized and removal remains a draft until saved', (
    tester,
  ) async {
    final photo = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.orange, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(800, 400);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final result = await profileThumbnail(data!.buffer.asUint8List());
      final codec = await ui.instantiateImageCodec(result);
      final decoded = (await codec.getNextFrame()).image;
      expect(decoded.width, 384);
      expect(decoded.height, 192);
      decoded.dispose();
      codec.dispose();
      image.dispose();
      picture.dispose();
      return result;
    });
    final profiles = ProfileService();
    await profiles.ready;
    await profiles.save('one', LocalProfile(name: 'Ishtiak', photo: photo));
    final auth = Auth();
    await openEditor(tester, profiles, auth);
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Photo'));
    await tester.pumpAndSettle();
    expect(profiles.forAccount('one')!.photo, isNotNull);
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(profiles.forAccount('one')!.photo, isNull);
    expect(profiles.forAccount('one')!.hideGooglePhoto, isTrue);
    await tester.pumpWidget(const SizedBox());
    profiles.dispose();
    auth.dispose();
  });

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Render Edit Profile preview', (tester) async {
    final profiles = ProfileService();
    await profiles.ready;
    final auth = Auth();
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: RepaintBoundary(
          key: key,
          child: EditProfilePage(
            account: account,
            profiles: profiles,
            auth: auth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/edit_profile_preview.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    profiles.dispose();
    auth.dispose();
  }, skip: font.isEmpty);
}
