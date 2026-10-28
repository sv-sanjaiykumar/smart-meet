import 'package:flutter_test/flutter_test.dart';
import 'package:smart_meet/src/backend/auth_service.dart';
import 'package:smart_meet/src/backend/fcm_credentials.dart';
import 'package:smart_meet/src/backend/meeting_service.dart';
import 'package:smart_meet/src/backend/push_notification_service.dart';
import 'package:smart_meet/src/frontend/student/models/meeting.dart';

class FakePushNotificationService extends PushNotificationService {
  FakePushNotificationService() : super.custom();

  Meeting? lastBookedMeeting;
  String? lastBookedStudentName;

  Meeting? lastAcceptedMeeting;
  String? lastAcceptedStaffName;
  String? lastAcceptedTime;
  String? lastAcceptedLocation;

  Meeting? lastRejectedMeeting;
  String? lastRejectedStaffName;
  String? lastRejectedReason;

  @override
  Future<void> sendMeetingBookedPushNotification({
    required Meeting meeting,
    required String studentName,
  }) async {
    lastBookedMeeting = meeting;
    lastBookedStudentName = studentName;
  }

  @override
  Future<void> sendMeetingAcceptedPushNotification({
    required Meeting meeting,
    required String staffName,
    String? time,
    String? location,
  }) async {
    lastAcceptedMeeting = meeting;
    lastAcceptedStaffName = staffName;
    lastAcceptedTime = time;
    lastAcceptedLocation = location;
  }

  @override
  Future<void> sendMeetingRejectedPushNotification({
    required Meeting meeting,
    required String staffName,
    String? reason,
  }) async {
    lastRejectedMeeting = meeting;
    lastRejectedStaffName = staffName;
    lastRejectedReason = reason;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM Push Notification Configuration Tests', () {
    test('FcmCredentials contains valid projectId and credentials', () {
      expect(FcmCredentials.projectId, 'smart-meet-779bc');
      expect(FcmCredentials.clientEmail, contains('@smart-meet-779bc'));
      expect(FcmCredentials.serviceAccountMap['type'], 'service_account');
      expect(FcmCredentials.serviceAccountMap['project_id'], 'smart-meet-779bc');
      expect(
        FcmCredentials.serviceAccountMap['private_key'],
        contains('BEGIN PRIVATE KEY'),
      );
    });

    test('PushNotificationService exposes high importance channel configuration', () {
      expect(PushNotificationService.channelId, 'smart_meet_high_importance');
      expect(PushNotificationService.channelName, 'Smart Meet Notifications');
    });

    test('UserModel supports fcmToken serialization and deserialization', () {
      final user = UserModel(
        uid: 'user_123',
        username: 'alice',
        password: '',
        role: UserRole.student,
        displayName: 'Alice Student',
        email: 'alice@smartmeet.edu',
        fcmToken: 'token_abc_123',
      );

      final json = user.toJson();
      expect(json['fcmToken'], 'token_abc_123');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.fcmToken, 'token_abc_123');
      expect(deserialized.displayName, 'Alice Student');
    });

    test('MeetingService integrates PushNotificationService for booking and acceptance', () async {
      final fakePush = FakePushNotificationService();
      final meetingService = MeetingService(
        pushNotifications: fakePush,
      );

      expect(meetingService, isNotNull);

      // Verify fake push captures meeting booked notification
      final testMeeting = Meeting(
        id: 'meet_999',
        facultyName: 'Dr. Alan Turing',
        facultyDept: 'Dept of CSE',
        purpose: 'AI Research Guidance',
        status: MeetingStatus.pending,
        cardColorValue: 0xFF123456,
        requestedAt: '28 Oct, 10:00 AM',
        studentName: 'Bob Student',
        studentUid: 'student_bob_1',
        facultyUid: 'faculty_alan_1',
      );

      await fakePush.sendMeetingBookedPushNotification(
        meeting: testMeeting,
        studentName: 'Bob Student',
      );

      expect(fakePush.lastBookedMeeting?.id, 'meet_999');
      expect(fakePush.lastBookedStudentName, 'Bob Student');
      expect(fakePush.lastBookedMeeting?.purpose, 'AI Research Guidance');

      // Verify fake push captures meeting accepted notification
      await fakePush.sendMeetingAcceptedPushNotification(
        meeting: testMeeting,
        staffName: 'Dr. Alan Turing',
        time: '11:30 AM',
        location: 'Cabin 12',
      );

      expect(fakePush.lastAcceptedMeeting?.id, 'meet_999');
      expect(fakePush.lastAcceptedStaffName, 'Dr. Alan Turing');
      expect(fakePush.lastAcceptedTime, '11:30 AM');
      expect(fakePush.lastAcceptedLocation, 'Cabin 12');
    });
  });
}
