import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../frontend/student/models/meeting.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Orchestrates the full meeting lifecycle:
/// submit → accept / reject / complete → notifications.
///
/// All pages should prefer this service over calling [LocalStorageService]
/// directly so that notifications are emitted automatically.
class MeetingService {
  MeetingService({
    LocalStorageService? storage,
    NotificationService? notifications,
    AuthService? auth,
  })  : _storage = storage ?? LocalStorageService(),
        _notifications = notifications ?? NotificationService(),
        _auth = auth ?? AuthService();

  final LocalStorageService _storage;
  final NotificationService _notifications;
  final AuthService _auth;

  // ── card-colour palette ───────────────────────────────────────────────────
  static const List<int> _palette = [
    0xFFE8F4FD, // soft blue
    0xFFF0F7FF, // ice
    0xFFFFF3E0, // amber-tinted
    0xFFF3E5F5, // lavender
    0xFFE8F5E9, // mint
    0xFFFCE4EC, // rose
    0xFFE0F2F1, // teal
    0xFFFFF8E1, // warm yellow
  ];

  int _pickColor(int index) => _palette[index % _palette.length];

  // ── read helpers ──────────────────────────────────────────────────────────

  Future<List<Meeting>> getMeetings() => _storage.getMeetings();

  Future<Meeting?> getMeetingById(String id) =>
      _storage.getMeetingById(id);

  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status) =>
      _storage.getMeetingsByStatus(status);

  // ── student actions ───────────────────────────────────────────────────────

  /// Creates and persists a new meeting request from the currently logged-in
  /// student.  Also fires notifications to the student (confirmation) and the
  /// relevant staff (new request).
  ///
  /// [staffUsername] – the username of the target faculty account (used for
  /// routing the staff notification). Pass `null` to skip the staff ping.
  Future<Meeting> submitMeetingRequest({
    required String facultyName,
    required String facultyDept,
    required String purpose,
    String? staffUsername,
  }) async {
    final user = await _auth.getCurrentUser();
    final studentName = user?.displayName ?? 'Student';
    final studentUsername = user?.username ?? 'student';

    final existingMeetings = await _storage.getMeetings();

    final newMeeting = Meeting(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      facultyName: facultyName,
      facultyDept: facultyDept,
      purpose: purpose,
      status: MeetingStatus.pending,
      cardColorValue: _pickColor(existingMeetings.length),
      requestedAt: DateFormat('d MMM, h:mm a').format(DateTime.now()),
      isPinned: false,
      studentName: studentName,
    );

    // Prepend so newest appears first
    await _storage.saveMeetings([newMeeting, ...existingMeetings]);

    // Fire notifications
    await _notifications.onMeetingRequested(
      studentUsername: studentUsername,
      studentDisplayName: studentName,
      staffUsername: staffUsername ?? 'staff',
      meeting: newMeeting,
    );

    return newMeeting;
  }

  // ── staff actions ─────────────────────────────────────────────────────────

  /// Accepts a meeting request.
  ///
  /// [studentUsername] – username of the student who made the request (used
  /// to route the acceptance notification).
  Future<void> acceptMeeting(
    String meetingId, {
    String? studentUsername,
    String? time,
    String? location,
  }) async {
    await _storage.updateMeetingStatus(
      meetingId,
      MeetingStatus.accepted,
      'Accepted by faculty',
    );

    if (time != null || location != null) {
      await _storage.updateMeetingDetails(
        meetingId,
        time: time,
        location: location,
      );
    }

    final meeting = await _storage.getMeetingById(meetingId);
    if (meeting == null) return;

    final staffUser = await _auth.getCurrentUser();
    await _notifications.onMeetingAccepted(
      studentUsername: studentUsername ?? _usernameFromMeeting(meeting),
      staffDisplayName: staffUser?.displayName ?? 'Faculty',
      meeting: meeting,
    );
  }

  /// Rejects a meeting request with an optional [reason].
  Future<void> rejectMeeting(
    String meetingId, {
    String? studentUsername,
    String? reason,
  }) async {
    await _storage.updateMeetingStatus(
      meetingId,
      MeetingStatus.rejected,
      reason ?? 'Rejected by faculty',
    );

    final meeting = await _storage.getMeetingById(meetingId);
    if (meeting == null) return;

    final staffUser = await _auth.getCurrentUser();
    await _notifications.onMeetingRejected(
      studentUsername: studentUsername ?? _usernameFromMeeting(meeting),
      staffDisplayName: staffUser?.displayName ?? 'Faculty',
      meeting: meeting,
    );
  }

  /// Marks a meeting as completed.
  Future<void> completeMeeting(String meetingId) =>
      _storage.completeMeeting(meetingId);

  /// Edits the time and/or venue of an accepted meeting.
  Future<void> editMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  }) =>
      _storage.updateMeetingDetails(
        meetingId,
        time: time,
        location: location,
      );

  /// Permanently deletes a meeting.
  Future<void> deleteMeeting(String meetingId) =>
      _storage.deleteMeeting(meetingId);

  // ── internal ──────────────────────────────────────────────────────────────

  /// Derives a best-guess student username from the meeting's [studentName].
  /// Falls back to 'student' when nothing better is available.
  String _usernameFromMeeting(Meeting meeting) {
    final name = meeting.studentName;
    if (name == null || name.isEmpty || name == 'Student') return 'student';
    // Convert "Thoufik" → "thoufik", "Priya Nair" → "priya"
    return name.trim().split(' ').first.toLowerCase();
  }
}
