import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meet/src/frontend/staff/pages/staff_history_page.dart';
import 'package:smart_meet/src/frontend/student/models/meeting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();

  final sampleMeetings = [
    Meeting(
      id: 'req_101',
      facultyName: 'Anwar Raja',
      facultyDept: 'Dept of CSE',
      purpose: 'Project Guidance Discussion',
      time: '11:00 AM',
      location: 'TF-03',
      status: MeetingStatus.accepted,
      cardColorValue: 0xFFFFFFFF,
      requestedAt: '27 Oct, 10:30 AM',
      meetingDate: today,
      studentName: 'Alice Student',
    ),
    Meeting(
      id: 'req_102',
      facultyName: 'Anwar Raja',
      facultyDept: 'Dept of ECE',
      purpose: 'Lab Exam Clarification',
      status: MeetingStatus.pending,
      cardColorValue: 0xFFFFFFFF,
      requestedAt: '27 Oct, 11:00 AM',
      meetingDate: today,
      studentName: 'Bob Student',
    ),
    Meeting(
      id: 'req_103',
      facultyName: 'Anwar Raja',
      facultyDept: 'Dept of CSE',
      purpose: 'Course Registration Sign',
      time: '09:00 AM',
      location: 'Cabin 4',
      status: MeetingStatus.completed,
      cardColorValue: 0xFFFFFFFF,
      requestedAt: '27 Oct, 08:30 AM',
      meetingDate: today,
      studentName: 'Charlie Student',
    ),
    Meeting(
      id: 'req_104',
      facultyName: 'Anwar Raja',
      facultyDept: 'Dept of CSE',
      purpose: 'Internship Recommendation',
      status: MeetingStatus.rejected,
      cardColorValue: 0xFFFFFFFF,
      requestedAt: '27 Oct, 09:30 AM',
      meetingDate: today,
      studentName: 'David Student',
      denialReason: 'Faculty out of station',
    ),
  ];

  testWidgets('StaffHistoryPage displays meetings for today across categories',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaffHistoryPage(
            meetings: sampleMeetings,
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and day display
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Sort By'), findsOneWidget);

    // Verify that all 4 meetings for today are present on the page
    expect(find.text('Project Guidance Discussion'), findsOneWidget);
    expect(find.text('Lab Exam Clarification'), findsOneWidget);
    expect(find.text('Course Registration Sign'), findsOneWidget);
    expect(find.text('Internship Recommendation'), findsOneWidget);

    // Verify student names are rendered
    expect(find.text('Alice Student'), findsOneWidget);
    expect(find.text('Bob Student'), findsOneWidget);
    expect(find.text('Charlie Student'), findsOneWidget);
    expect(find.text('David Student'), findsOneWidget);

    // Verify status badges
    expect(find.text('Scheduled'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);

    // Filter by Scheduled
    await tester.tap(find.text('Scheduled').first);
    await tester.pumpAndSettle();
    expect(find.text('Project Guidance Discussion'), findsOneWidget);
    expect(find.text('Lab Exam Clarification'), findsNothing);

    // Filter by Pending
    await tester.tap(find.text('Pending').first);
    await tester.pumpAndSettle();
    expect(find.text('Lab Exam Clarification'), findsOneWidget);
    expect(find.text('Project Guidance Discussion'), findsNothing);
  });

  testWidgets('StaffHistoryPage shows empty state when day has no meetings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaffHistoryPage(
            meetings: const [],
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No meetings on this day'), findsOneWidget);
  });
}
