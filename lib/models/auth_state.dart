class AuthAccount {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const AuthAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final AuthAccount account;
  const AuthAuthenticated(this.account);
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
