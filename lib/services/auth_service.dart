import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_state.dart';

abstract class AuthService extends ChangeNotifier {
  AuthState get state;
  Future<void> signIn();
  Future<void> signOut();
}

class GoogleAuthService extends ChangeNotifier implements AuthService {
  GoogleAuthService({String? serverClientId, GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    ready = _init(serverClientId);
  }

  static const rememberedAccountKey = 'remembered_google_account';
  final GoogleSignIn _googleSignIn;
  late final Future<void> ready;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  GoogleSignInAccount? _user;
  bool _disposed = false;
  AuthState _state = const AuthInitial();
  @override
  AuthState get state => _state;

  void _publish(AuthState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  Future<void> _init(String? clientId) async {
    try {
      await _googleSignIn.initialize(serverClientId: clientId);
      if (_disposed) return;
      _subscription = _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _accept(event.user);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _user = null;
          _publish(const AuthUnauthenticated());
          _forget();
        }
      }, onError: (Object error) => _publish(AuthError(error.toString())));
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(rememberedAccountKey);
      if (_user != null || _disposed) return;
      if (saved == null) {
        _publish(const AuthUnauthenticated());
      } else {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        _publish(
          AuthRemembered(
            AuthAccount(
              id: data['id'] as String,
              email: data['email'] as String,
              displayName: data['displayName'] as String?,
              photoUrl: data['photoUrl'] as String?,
            ),
          ),
        );
      }
      // Android lightweight authentication may show an account chooser.
      // Restore display metadata here; cloud actions verify with Google.
    } catch (_) {
      _publish(const AuthUnauthenticated());
    }
  }

  Future<void> _accept(GoogleSignInAccount user) async {
    if (_disposed) return;
    _user = user;
    _publish(
      AuthAuthenticated(
        AuthAccount(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
        ),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    if (_user != user || _disposed) return;
    await prefs.setString(
      rememberedAccountKey,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
      }),
    );
  }

  Future<void> _forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(rememberedAccountKey);
  }

  /// Only invoked following an explicit sign-in or cloud action.
  Future<GoogleSignInAccount?> accountForCloudAction() async {
    await ready;
    if (_user != null) return _user;
    await signIn();
    return _user;
  }

  @override
  Future<void> signIn() async {
    await ready;
    if (_disposed || _state is AuthLoading) return;
    final previous = _state;
    _publish(const AuthLoading());
    try {
      await _accept(await _googleSignIn.authenticate());
    } catch (_) {
      _publish(previous);
    }
  }

  @override
  Future<void> signOut() async {
    await ready;
    await _googleSignIn.signOut();
    _user = null;
    await _forget();
    _publish(const AuthUnauthenticated());
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
