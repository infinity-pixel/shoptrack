import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/services/auth_service.dart';

void main() {
  test(
    'Firebase authentication remains optional for local-only test services',
    () {
      final service = GoogleAuthService();
      expect(service, isA<GoogleAuthService>());
      service.dispose();
    },
  );
}
