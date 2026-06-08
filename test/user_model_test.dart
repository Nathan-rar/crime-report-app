import 'package:crime_report_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults role to user when role is missing', () {
    final user = UserModel.fromMap('uid-1', {
      'email': 'pelapor@example.com',
      'name': 'Pelapor',
      'createdAt': DateTime(2026),
    });

    expect(user.role, UserRole.user);
    expect(user.isAdmin, isFalse);
  });

  test('parses admin role from Firestore map', () {
    final user = UserModel.fromMap('uid-2', {
      'email': 'admin@example.com',
      'name': 'Admin',
      'role': 'admin',
      'createdAt': DateTime(2026),
    });

    expect(user.role, UserRole.admin);
    expect(user.isAdmin, isTrue);
  });
}
