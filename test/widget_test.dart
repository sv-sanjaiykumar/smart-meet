import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_meet/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'student login navigates to the student dashboard and shows empty state until requests are created',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'student');
      await tester.enterText(find.byType(TextField).at(1), 'student123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Hey, Thoufik!'), findsOneWidget);
      expect(
        find.text(
          'No accepted meetings yet. Your requests will appear here once faculty responds.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'staff login navigates to the staff page and shows empty pending queue until requests are created',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'staff');
      await tester.enterText(find.byType(TextField).at(1), 'staff123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Requests'), findsWidgets);
      expect(
        find.text('No meetings yet. New student requests will appear here.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.text('No meetings on this day'), findsOneWidget);

      await tester.tap(find.byTooltip('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byTooltip('Sort requests'), findsOneWidget);
    },
  );
}
