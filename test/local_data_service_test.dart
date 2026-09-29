import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_meet/src/backend/local_storage_service.dart';
import 'package:smart_meet/src/frontend/student/models/meeting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty and only shows persisted meetings created by the user', () async {
    final service = LocalStorageService();

    final meetings = await service.getMeetings();
    expect(meetings, isEmpty);

    final meeting = Meeting(
      id: 'demo_meeting_1',
      facultyName: 'Prof. Lakshmanan',
      facultyDept: 'Dept of CSE',
      purpose: 'Project Discussion',
      time: '12:30 PM',
      location: 'TF-23',
      status: MeetingStatus.pending,
      cardColorValue: 0xFFBFE0FC,
      isPinned: false,
      requestedAt: '28 Sep, 10:00 AM',
      studentName: 'Student 4',
    );

    await service.addMeeting(meeting);
    final saved = await service.getMeetings();

    expect(saved.any((item) => item.id == meeting.id), isTrue);
    expect(saved.firstWhere((item) => item.id == meeting.id).status, MeetingStatus.pending);
  });

  test('updates a meeting status and keeps the change persisted', () async {
    final service = LocalStorageService();
    final meeting = Meeting(
      id: 'demo_meeting_2',
      facultyName: 'Prof. Alex',
      facultyDept: 'Dept of ECE',
      purpose: 'Academic doubts',
      time: '02:00 PM',
      location: 'AB-12',
      status: MeetingStatus.pending,
      cardColorValue: 0xFFF3F7FF,
      requestedAt: '28 Sep, 09:30 AM',
      studentName: 'Student 5',
    );

    await service.addMeeting(meeting);
    await service.updateMeetingStatus(
      meeting.id,
      MeetingStatus.accepted,
      'Approved by faculty',
    );

    final savedMeeting = await service.getMeetingById(meeting.id);
    expect(savedMeeting, isNotNull);
    expect(savedMeeting!.status, MeetingStatus.accepted);
    expect(savedMeeting.denialReason, 'Approved by faculty');
  });
}
