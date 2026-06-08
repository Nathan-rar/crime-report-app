import 'package:crime_report_app/screens/admin_reports_screen.dart';
import 'package:crime_report_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows admin empty state when there are no reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AdminReportsScreen(reportsStream: Stream.value(const [])),
      ),
    );
    await tester.pump();

    expect(find.text('Belum ada laporan'), findsOneWidget);
    expect(find.text('Buat Laporan'), findsWidgets);
  });
}
