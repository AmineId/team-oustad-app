import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/auth_service.dart';

void main() {
  group('AuthService.normalizeRole', () {
    test('reconnaît les quatre rôles', () {
      for (final role in ['owner', 'manager', 'coach', 'member']) {
        expect(AuthService.normalizeRole(role), role);
      }
      expect(AuthService.normalizeRole(' Owner '), 'owner');
    });

    test("l'ancien rôle admin devient manager", () {
      expect(AuthService.normalizeRole('admin'), 'manager');
      expect(AuthService.normalizeRole(' ADMIN '), 'manager');
    });

    test('rôle inconnu ou absent → null', () {
      expect(AuthService.normalizeRole('superuser'), isNull);
      expect(AuthService.normalizeRole(null), isNull);
    });
  });
}
