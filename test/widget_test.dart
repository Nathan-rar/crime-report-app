import 'package:flutter_test/flutter_test.dart';

import 'package:crime_report_app/main.dart';

void main() {
  testWidgets('shows Firebase setup error when Firebase is not configured',
      (tester) async {
    await tester.pumpWidget(const CrimeReportApp(firebaseError: 'missing config'));

    expect(find.text('Firebase belum siap'), findsOneWidget);
    expect(find.textContaining('missing config'), findsOneWidget);
  });
}
