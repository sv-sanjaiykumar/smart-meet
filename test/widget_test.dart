import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_meet/main.dart';

void main() {
  testWidgets('student dashboard shows the next meeting', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hey, Thoufik!'), findsOneWidget);
    expect(find.text('Meeting with\nProf. Lakshmanan'), findsOneWidget);
    expect(find.text('TF-23'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
  });

  testWidgets('student bottom navigation switches destinations', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);
  });
}