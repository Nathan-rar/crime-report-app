import 'package:crime_report_app/screens/admin_login_screen.dart';
import 'package:crime_report_app/services/auth_service.dart';
import 'package:crime_report_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows separate admin login form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const AdminLoginScreen()),
    );

    expect(find.text('Masuk Admin'), findsWidgets);
    expect(find.text('Email admin'), findsOneWidget);
    expect(find.text('Password admin'), findsOneWidget);
    expect(find.text('Kembali ke login pelapor'), findsOneWidget);
  });

  test('uses local admin credentials', () {
    expect(AuthService.localAdminEmail, 'admin@local.app');
    expect(AuthService.localAdminPassword, 'admin123');
  });
}
