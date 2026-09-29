import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../frontend/student/models/meeting.dart';
import 'meeting_repository.dart';

class LocalStorageService implements MeetingRepository {
  static const String _key = 'smart_meet_meetings';

  @override
  Future<List<Meeting>> getMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded.map((item) => Meeting.fromJson(item as Map<String, dynamic>)).toList();
    } on FormatException {
      await prefs.remove(_key);
      return [];
    }
  }

  @override
  Future<Meeting?> getMeetingById(String id) async {
    final meetings = await getMeetings();
    return meetings.cast<Meeting?>().firstWhere(
      (meeting) => meeting != null && meeting.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> addMeeting(Meeting meeting) async {
    final meetings = await getMeetings();
    final updated = [...meetings, meeting];
    await saveMeetings(updated);
  }

  @override
  Future<void> saveMeetings(List<Meeting> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(meetings.map((m) => m.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  @override
  Future<void> updateMeetingStatus(String meetingId, MeetingStatus status, [String? reason]) async {
    final meetings = await getMeetings();
    final index = meetings.indexWhere((meeting) => meeting.id == meetingId);

    if (index == -1) return;

    final updatedMeeting = Meeting(
      id: meetings[index].id,
      facultyName: meetings[index].facultyName,
      facultyDept: meetings[index].facultyDept,
      purpose: meetings[index].purpose,
      time: meetings[index].time,
      location: meetings[index].location,
      status: status,
      cardColorValue: meetings[index].cardColorValue,
      isPinned: meetings[index].isPinned,
      requestedAt: meetings[index].requestedAt,
      denialReason: reason ?? meetings[index].denialReason,
      studentName: meetings[index].studentName,
    );

    meetings[index] = updatedMeeting;
    await saveMeetings(meetings);
  }

}
