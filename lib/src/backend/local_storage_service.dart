import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../frontend/student/models/meeting.dart';
import 'meeting_repository.dart';

/// SharedPreferences-backed implementation of [MeetingRepository].
///
/// All meetings are serialised as a JSON array stored under [_key].
class LocalStorageService implements MeetingRepository {
  static const String _key = 'smart_meet_meetings';

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Loads and deserialises all meetings from SharedPreferences.
  @override
  Future<List<Meeting>> getMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);

    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((item) => Meeting.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      await prefs.remove(_key);
      return [];
    }
  }

  @override
  Future<Meeting?> getMeetingById(String id) async {
    final meetings = await getMeetings();
    return meetings.cast<Meeting?>().firstWhere(
      (m) => m != null && m.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> addMeeting(Meeting meeting) async {
    final meetings = await getMeetings();
    await saveMeetings([...meetings, meeting]);
  }

  @override
  Future<void> saveMeetings(List<Meeting> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(meetings.map((m) => m.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  // ── status management ─────────────────────────────────────────────────────

  @override
  Future<void> updateMeetingStatus(
    String meetingId,
    MeetingStatus status, [
    String? reason,
  ]) async {
    final meetings = await getMeetings();
    final index = meetings.indexWhere((m) => m.id == meetingId);
    if (index == -1) return;

    final old = meetings[index];
    meetings[index] = Meeting(
      id: old.id,
      facultyName: old.facultyName,
      facultyDept: old.facultyDept,
      purpose: old.purpose,
      time: old.time,
      location: old.location,
      status: status,
      cardColorValue: old.cardColorValue,
      isPinned: old.isPinned,
      requestedAt: old.requestedAt,
      denialReason: reason ?? old.denialReason,
      studentName: old.studentName,
    );

    await saveMeetings(meetings);
  }

  @override
  Future<void> completeMeeting(String meetingId) =>
      updateMeetingStatus(meetingId, MeetingStatus.completed);

  // ── detail edits ──────────────────────────────────────────────────────────

  @override
  Future<void> updateMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  }) async {
    final meetings = await getMeetings();
    final index = meetings.indexWhere((m) => m.id == meetingId);
    if (index == -1) return;

    final old = meetings[index];
    meetings[index] = Meeting(
      id: old.id,
      facultyName: old.facultyName,
      facultyDept: old.facultyDept,
      purpose: old.purpose,
      time: time?.trim().isEmpty == true ? null : (time ?? old.time),
      location: location?.trim().isEmpty == true
          ? null
          : (location ?? old.location),
      status: old.status,
      cardColorValue: old.cardColorValue,
      isPinned: old.isPinned,
      requestedAt: old.requestedAt,
      denialReason: old.denialReason,
      studentName: old.studentName,
    );

    await saveMeetings(meetings);
  }

  // ── deletion ──────────────────────────────────────────────────────────────

  @override
  Future<void> deleteMeeting(String meetingId) async {
    final meetings = await getMeetings();
    meetings.removeWhere((m) => m.id == meetingId);
    await saveMeetings(meetings);
  }

  // ── queries ───────────────────────────────────────────────────────────────

  @override
  Future<List<Meeting>> getMeetingsForStudent(String studentName) async {
    final meetings = await getMeetings();
    return meetings
        .where((m) =>
            m.studentName?.toLowerCase() == studentName.toLowerCase())
        .toList();
  }

  @override
  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status) async {
    final meetings = await getMeetings();
    return meetings.where((m) => m.status == status).toList();
  }
}
