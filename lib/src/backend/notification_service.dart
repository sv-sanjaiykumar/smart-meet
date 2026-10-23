import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/notification_model.dart';
import '../frontend/student/models/meeting.dart';

export 'models/notification_model.dart';

/// Persists and retrieves in-app notifications for Smart Meet.
///
/// Notifications are user-scoped — each username gets its own key so
/// students and staff see different notifications.
class NotificationService {
  static const String _prefix = 'smart_meet_notifs_';

  // ── helpers ───────────────────────────────────────────────────────────────

  String _key(String username) => '$_prefix${username.toLowerCase()}';

  Future<List<AppNotification>> _load(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(username));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _save(String username, List<AppNotification> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(username),
      jsonEncode(notifs.map((n) => n.toJson()).toList()),
    );
  }

  // ── public API ────────────────────────────────────────────────────────────

  /// Returns all notifications for [username], newest first.
  Future<List<AppNotification>> getNotifications(String username) async {
    final notifs = await _load(username);
    notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifs;
  }

  /// Returns the count of unread notifications for [username].
  Future<int> getUnreadCount(String username) async {
    final notifs = await _load(username);
    return notifs.where((n) => !n.isRead).length;
  }

  /// Marks all notifications as read for [username].
  Future<void> markAllRead(String username) async {
    final notifs = await _load(username);
    final updated = notifs.map((n) => n.copyWith(isRead: true)).toList();
    await _save(username, updated);
  }

  /// Marks a single notification as read.
  Future<void> markRead(String username, String notificationId) async {
    final notifs = await _load(username);
    final index = notifs.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    notifs[index] = notifs[index].copyWith(isRead: true);
    await _save(username, notifs);
  }

  /// Clears all notifications for [username].
  Future<void> clearAll(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(username));
  }

  /// Creates and persists a notification.
  Future<void> _push(String username, AppNotification notif) async {
    final notifs = await _load(username);
    notifs.insert(0, notif);
    // keep at most 100 notifications per user
    if (notifs.length > 100) notifs.removeRange(100, notifs.length);
    await _save(username, notifs);
  }

  // ── domain-specific helpers ───────────────────────────────────────────────

  /// Called when a student submits a new meeting request.
  ///
  /// - Sends a [NotificationType.newRequest] to [staffUsername].
  /// - Sends a [NotificationType.system] confirmation to [studentUsername].
  Future<void> onMeetingRequested({
    required String studentUsername,
    required String studentDisplayName,
    required String staffUsername,
    required Meeting meeting,
  }) async {
    final id = 'notif_${DateTime.now().millisecondsSinceEpoch}';

    // Notify staff
    await _push(
      staffUsername,
      AppNotification(
        id: '${id}_staff',
        title: 'New Meeting Request',
        body:
            '$studentDisplayName has requested a meeting for "${meeting.purpose}".',
        type: NotificationType.newRequest,
        createdAt: DateTime.now(),
        meetingId: meeting.id,
      ),
    );

    // Confirm to student
    await _push(
      studentUsername,
      AppNotification(
        id: '${id}_student',
        title: 'Request Sent',
        body:
            'Your meeting request to ${meeting.facultyName} has been submitted and is pending review.',
        type: NotificationType.system,
        createdAt: DateTime.now(),
        meetingId: meeting.id,
      ),
    );
  }

  /// Called when a staff member accepts a student's meeting request.
  Future<void> onMeetingAccepted({
    required String studentUsername,
    required String staffDisplayName,
    required Meeting meeting,
  }) async {
    await _push(
      studentUsername,
      AppNotification(
        id: 'notif_acc_${meeting.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Meeting Accepted! 🎉',
        body:
            '$staffDisplayName accepted your "${meeting.purpose}" request.'
            '${meeting.time != null ? " Time: ${meeting.time}" : ""}'
            '${meeting.location != null ? " · Venue: ${meeting.location}" : ""}',
        type: NotificationType.accepted,
        createdAt: DateTime.now(),
        meetingId: meeting.id,
      ),
    );
  }

  /// Called when a staff member rejects a student's meeting request.
  Future<void> onMeetingRejected({
    required String studentUsername,
    required String staffDisplayName,
    required Meeting meeting,
  }) async {
    await _push(
      studentUsername,
      AppNotification(
        id: 'notif_rej_${meeting.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Meeting Declined',
        body:
            '$staffDisplayName declined your "${meeting.purpose}" request.'
            '${meeting.denialReason != null ? ' Reason: ${meeting.denialReason}' : ''}',
        type: NotificationType.rejected,
        createdAt: DateTime.now(),
        meetingId: meeting.id,
      ),
    );
  }

  /// Sends a reminder notification to [username] about an upcoming meeting.
  Future<void> sendReminder({
    required String username,
    required Meeting meeting,
  }) async {
    await _push(
      username,
      AppNotification(
        id: 'notif_rem_${meeting.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Upcoming Meeting Reminder',
        body:
            'You have a meeting for "${meeting.purpose}" with ${meeting.facultyName}.'
            '${meeting.time != null ? " Time: ${meeting.time}" : ""}'
            '${meeting.location != null ? " · Venue: ${meeting.location}" : ""}',
        type: NotificationType.reminder,
        createdAt: DateTime.now(),
        meetingId: meeting.id,
      ),
    );
  }
}
