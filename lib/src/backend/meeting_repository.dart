import '../frontend/student/models/meeting.dart';

/// Abstract contract for all meeting persistence backends.
abstract class MeetingRepository {
  /// Returns all meetings in the store.
  Future<List<Meeting>> getMeetings();

  /// Returns a single meeting by [id], or null if not found.
  Future<Meeting?> getMeetingById(String id);

  /// Appends a new [meeting] to the store.
  Future<void> addMeeting(Meeting meeting);

  /// Overwrites the entire store with [meetings].
  Future<void> saveMeetings(List<Meeting> meetings);

  /// Updates the status (and optional reason) of the meeting with [meetingId].
  Future<void> updateMeetingStatus(
    String meetingId,
    MeetingStatus status, [
    String? reason,
  ]);

  /// Updates the time and location of an accepted meeting.
  Future<void> updateMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  });

  /// Permanently removes a meeting from the store.
  Future<void> deleteMeeting(String meetingId);

  /// Returns all meetings for a given student name.
  Future<List<Meeting>> getMeetingsForStudent(String studentName);

  /// Returns all meetings with a given status.
  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status);

  /// Marks a meeting as completed.
  Future<void> completeMeeting(String meetingId);
}
