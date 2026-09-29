import '../frontend/student/models/meeting.dart';

abstract class MeetingRepository {
  Future<List<Meeting>> getMeetings();
  Future<Meeting?> getMeetingById(String id);
  Future<void> addMeeting(Meeting meeting);
  Future<void> saveMeetings(List<Meeting> meetings);
  Future<void> updateMeetingStatus(String meetingId, MeetingStatus status, [String? reason]);
}
