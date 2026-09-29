import '../../../backend/local_storage_service.dart';
import '../models/meeting.dart';

class StorageService {
  final LocalStorageService _localStorageService = LocalStorageService();

  Future<void> saveMeetings(List<Meeting> meetings) async {
    await _localStorageService.saveMeetings(meetings);
  }

  Future<List<Meeting>> getMeetings() async {
    return _localStorageService.getMeetings();
  }

  Future<Meeting?> getMeetingById(String id) async {
    return _localStorageService.getMeetingById(id);
  }

  Future<void> addMeeting(Meeting meeting) async {
    await _localStorageService.addMeeting(meeting);
  }

  Future<void> updateMeetingStatus(String meetingId, MeetingStatus status, [String? reason]) async {
    await _localStorageService.updateMeetingStatus(meetingId, status, reason);
  }
}
