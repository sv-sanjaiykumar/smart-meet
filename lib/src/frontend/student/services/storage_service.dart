import 'package:shared_preferences/shared_preferences.dart';

import '../../../backend/meeting_service.dart';
import '../models/meeting.dart';

/// Student-side service backed by Firestore via [MeetingService].
/// Also cleans up any legacy local storage data so only database data is shown.
class StorageService {
  StorageService({MeetingService? meetingService})
      : _meetingService = meetingService ?? MeetingService() {
    _cleanLegacyLocalStorage();
  }

  final MeetingService _meetingService;

  static void _cleanLegacyLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('smart_meet_meetings')) {
        await prefs.remove('smart_meet_meetings');
      }
    } catch (_) {}
  }

  Future<List<Meeting>> getMeetings() => _meetingService.getMeetings();

  Future<List<Meeting>> getMeetingsForCurrentStudent() =>
      _meetingService.getMeetingsForCurrentStudent();

  Stream<List<Meeting>> streamMeetingsForCurrentStudent() =>
      _meetingService.streamMeetingsForCurrentStudent();

  Future<Meeting?> getMeetingById(String id) =>
      _meetingService.getMeetingById(id);

  Future<void> addMeeting(Meeting meeting) =>
      _meetingService.saveMeeting(meeting);

  Future<void> saveMeetings(List<Meeting> meetings) async {
    for (final m in meetings) {
      await _meetingService.saveMeeting(m);
    }
  }

  Future<void> updateMeetingStatus(
    String meetingId,
    MeetingStatus status, [
    String? reason,
  ]) =>
      _meetingService.updateMeetingStatus(meetingId, status, reason);

  Future<void> updateMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  }) =>
      _meetingService.editMeetingDetails(meetingId, time: time, location: location);

  Future<void> deleteMeeting(String meetingId) =>
      _meetingService.deleteMeeting(meetingId);

  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status) =>
      _meetingService.getMeetingsByStatus(status);

  Future<void> togglePin(String meetingId, bool isPinned) =>
      _meetingService.togglePin(meetingId, isPinned);
}
