import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_meet/main.dart';
import 'package:smart_meet/src/backend/local_storage_service.dart';
import 'package:smart_meet/src/frontend/student/models/meeting.dart';

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

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notification'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.byTooltip('Sort notifications'), findsOneWidget);

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(find.text('Update now'), findsOneWidget);
      expect(find.text('Remind Later'), findsOneWidget);

      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Anwar Raja'), findsOneWidget);
      await tester.tap(find.byTooltip('Open account details'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Assistant Professor'), findsOneWidget);
      expect(find.text('MicroControllers'), findsOneWidget);
      expect(find.text('staff'), findsOneWidget);

      await tester.ensureVisible(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
    },
  );

  testWidgets(
    'staff notifications show saved meeting events and edit reminders',
    (WidgetTester tester) async {
      final storage = LocalStorageService();
      final requestedAt = DateFormat('d MMM, h:mm a').format(DateTime.now());
      await storage.saveMeetings([
        Meeting(
          id: 'notification_reminder',
          facultyName: 'Faculty Member',
          facultyDept: 'Dept of CSE',
          purpose: 'Project review',
          time: '1:10 PM',
          location: 'TF-13',
          status: MeetingStatus.accepted,
          cardColorValue: 0xFFFFFFFF,
          requestedAt: requestedAt,
          studentName: 'Sara Student',
        ),
        Meeting(
          id: 'notification_cancelled',
          facultyName: 'Faculty Member',
          facultyDept: 'Dept of ECE',
          purpose: 'Academic doubts',
          status: MeetingStatus.rejected,
          cardColorValue: 0xFFFFFFFF,
          requestedAt: requestedAt,
          denialReason: 'Faculty unavailable',
          studentName: 'Lee Student',
        ),
      ]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'staff');
      await tester.enterText(find.byType(TextField).at(1), 'staff123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Project review with Sara Student'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Cancelled: Faculty unavailable'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Edit reminder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '2:15 PM');
      await tester.enterText(find.byType(TextField).at(1), 'Room 204');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final updated = await storage.getMeetingById('notification_reminder');
      expect(updated?.time, '2:15 PM');
      expect(updated?.location, 'Room 204');
    },
  );

  testWidgets(
    'student status summary filters accepted, rejected, and pending meetings',
    (WidgetTester tester) async {
      final storage = LocalStorageService();
      final requestedAt = DateFormat('d MMM, h:mm a').format(DateTime.now());
      await storage.saveMeetings([
        Meeting(
          id: 'student_accepted',
          facultyName: 'Professor Accepted',
          facultyDept: 'Dept of CSE',
          purpose: 'Accepted meeting purpose',
          time: '10:30 AM',
          location: 'Room 101',
          status: MeetingStatus.accepted,
          cardColorValue: 0xFFBFE0FC,
          requestedAt: requestedAt,
        ),
        Meeting(
          id: 'student_rejected',
          facultyName: 'Professor Rejected',
          facultyDept: 'Dept of ECE',
          purpose: 'Rejected meeting purpose',
          status: MeetingStatus.rejected,
          cardColorValue: 0xFFBFE0FC,
          requestedAt: requestedAt,
          denialReason: 'Schedule unavailable',
        ),
        Meeting(
          id: 'student_pending',
          facultyName: 'Professor Pending',
          facultyDept: 'Dept of CSE',
          purpose: 'Pending meeting purpose',
          status: MeetingStatus.pending,
          cardColorValue: 0xFFBFE0FC,
          requestedAt: requestedAt,
        ),
      ]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'student');
      await tester.enterText(find.byType(TextField).at(1), 'student123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Accepted meeting purpose'), findsOneWidget);
      expect(find.text('Room 101'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('student-status-rejected')));
      await tester.pumpAndSettle();
      expect(find.text('Rejected meeting purpose'), findsOneWidget);
      expect(find.text('Accepted meeting purpose'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('student-status-pending')));
      await tester.pumpAndSettle();
      expect(find.text('Pending meeting purpose'), findsOneWidget);
      expect(find.text('Rejected meeting purpose'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('student-status-accepted')));
      await tester.pumpAndSettle();
      expect(find.text('Accepted meeting purpose'), findsOneWidget);
    },
  );
}
