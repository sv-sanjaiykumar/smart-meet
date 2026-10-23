import '../../../backend/local_storage_service.dart';
import '../models/meeting.dart';

/// Thin façade over [LocalStorageService] used by student-side pages.
///
/// For new meeting submissions that need notifications, prefer using
/// [MeetingService] (from the backend) directly.
class StorageService {
  final LocalStorageService _local = LocalStorageService();

  Future<void> saveMeetings(List<Meeting> meetings) =>
      _local.saveMeetings(meetings);

  Future<List<Meeting>> getMeetings() => _local.getMeetings();

  Future<Meeting?> getMeetingById(String id) =>
      _local.getMeetingById(id);

  Future<void> addMeeting(Meeting meeting) =>
      _local.addMeeting(meeting);

  Future<void> updateMeetingStatus(
    String meetingId,
    MeetingStatus status, [
    String? reason,
  ]) =>
      _local.updateMeetingStatus(meetingId, status, reason);

  Future<void> updateMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  }) =>
      _local.updateMeetingDetails(meetingId, time: time, location: location);

  Future<void> deleteMeeting(String meetingId) =>
      _local.deleteMeeting(meetingId);

  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status) =>
      _local.getMeetingsByStatus(status);
}
