import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_state.dart';

abstract class AuthService extends ChangeNotifier {
  AuthState get state;
  Future<void> signIn();
  Future<void> signOut();
}

class GoogleAuthService extends ChangeNotifier implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final String? _serverClientId;

  @override
  AuthState get state => _state;
  AuthState _state = const AuthInitial();

  GoogleAuthService({String? serverClientId}) : _serverClientId = serverClientId {
    _init();
  }

  Future<void> _init() async {
    try {
      // Note: initialize must be called exactly once before any other methods.
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );

      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final user = event.user;
          _state = AuthAuthenticated(AuthAccount(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
          ));
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _state = const AuthUnauthenticated();
        }
        notifyListeners();
      });

      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account == null) {
        _state = const AuthUnauthenticated();
        notifyListeners();
      }
    } catch (_) {
      // In test environments or if not configured, fallback to unauthenticated
      _state = const AuthUnauthenticated();
      notifyListeners();
    }
  }

  @override
  Future<void> signIn() async {
    _state = const AuthLoading();
    notifyListeners();
    try {
      await _googleSignIn.authenticate();
      // state update handled by stream
    } catch (e) {
      _state = AuthError(e.toString());
      notifyListeners();
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    // state update handled by stream
  }
}
