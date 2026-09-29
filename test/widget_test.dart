import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_meet/main.dart';
import 'package:smart_meet/src/frontend/login/login_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('student login navigates to the student dashboard and shows empty state until requests are created', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'student');
    await tester.enterText(find.byType(TextField).at(1), 'student123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Hey, Thoufik!'), findsOneWidget);
    expect(find.text('No accepted meetings yet. Your requests will appear here once faculty responds.'), findsOneWidget);
  });

  testWidgets('staff login navigates to the staff page and shows empty pending queue until requests are created', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'staff');
    await tester.enterText(find.byType(TextField).at(1), 'staff123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Requests'), findsWidgets);
    expect(find.text('No meetings yet. New student requests will appear here.'), findsOneWidget);
  });
}
