import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../frontend/student/models/meeting.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

/// Orchestrates the full meeting lifecycle backed by Firebase Firestore:
/// submit → accept / reject / complete → notifications.
///
/// Meetings are stored in the 'meetings' collection in Firestore and queried
/// by student UID so each student only sees their own meetings.
class MeetingService {
  MeetingService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    NotificationService? notifications,
    AuthService? authService,
    PushNotificationService? pushNotifications,
  })  : _injectedDb = db,
        _injectedAuth = auth,
        _notifications = notifications ?? NotificationService(),
        _authService = authService ?? AuthService(),
        _pushNotifications = pushNotifications ?? PushNotificationService();

  final FirebaseFirestore? _injectedDb;
  final FirebaseAuth? _injectedAuth;
  final NotificationService _notifications;
  final AuthService _authService;
  final PushNotificationService _pushNotifications;

  FirebaseFirestore? get _db {
    if (_injectedDb != null) return _injectedDb;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static const String _collection = 'meetings';

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

  /// Context-aware getter: returns meetings for current user based on their role and UID.
  Future<List<Meeting>> getMeetings() async {
    final user = await _authService.getCurrentUser();
    final role = user?.role ?? await _authService.getCurrentRole();
    final uid = user?.uid ?? _auth?.currentUser?.uid ?? '';

    if (role == UserRole.student) {
      return getMeetingsForStudent(uid);
    } else if (role == UserRole.staff) {
      return getMeetingsForStaff(user?.displayName, uid);
    } else {
      // Admin gets all meetings
      return getAllMeetings();
    }
  }

  /// Returns only the meetings created by the specified student UID.
  Future<List<Meeting>> getMeetingsForStudent(String studentUid) async {
    final db = _db;
    if (db == null || studentUid.isEmpty) return [];
    try {
      final snap = await db
          .collection(_collection)
          .where('studentUid', isEqualTo: studentUid)
          .get();

      final list = snap.docs.map((doc) => Meeting.fromFirestore(doc)).toList();
      // Sort newest first
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.requestedAt.compareTo(a.requestedAt);
      });
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching student meetings: $e');
      return [];
    }
  }

  /// Returns meetings for the currently logged in student.
  Future<List<Meeting>> getMeetingsForCurrentStudent() async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || uid.isEmpty) return [];
    return getMeetingsForStudent(uid);
  }

  /// Real-time stream of meetings for the current student.
  Stream<List<Meeting>> streamMeetingsForCurrentStudent() {
    final db = _db;
    final uid = _auth?.currentUser?.uid;
    if (db == null || uid == null || uid.isEmpty) {
      return Stream.value([]);
    }
    return db
        .collection(_collection)
        .where('studentUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => Meeting.fromFirestore(doc)).toList();
          list.sort((a, b) {
            if (a.createdAt != null && b.createdAt != null) {
              return b.createdAt!.compareTo(a.createdAt!);
            }
            return b.requestedAt.compareTo(a.requestedAt);
          });
          return list;
        });
  }

  /// Returns meetings for a staff member (matched by facultyUid or facultyName).
  Future<List<Meeting>> getMeetingsForStaff(String? facultyName, String? facultyUid) async {
    final db = _db;
    if (db == null) return [];
    try {
      final snap = await db.collection(_collection).get();
      final all = snap.docs.map((doc) => Meeting.fromFirestore(doc)).toList();

      final normalizedName = facultyName?.trim().toLowerCase();
      final filtered = all.where((m) {
        if (facultyUid != null && facultyUid.isNotEmpty && m.facultyUid == facultyUid) {
          return true;
        }
        if (normalizedName != null && normalizedName.isNotEmpty) {
          final target = m.facultyName.toLowerCase();
          if (target.contains(normalizedName) || normalizedName.contains(target)) {
            return true;
          }
        }
        return false;
      }).toList();

      final result = filtered.isNotEmpty ? filtered : all;
      final seen = <String>{};
      final unique = result.where((m) => seen.add(m.id)).toList();
      unique.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.requestedAt.compareTo(a.requestedAt);
      });
      return unique;
    } catch (e) {
      debugPrint('❌ Error fetching staff meetings: $e');
      return [];
    }
  }

  /// Real-time stream of meetings for a staff member (matched by facultyUid or facultyName).
  Stream<List<Meeting>> streamMeetingsForStaff(String? facultyName, String? facultyUid) {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db.collection(_collection).snapshots().map((snap) {
      final all = snap.docs.map((doc) => Meeting.fromFirestore(doc)).toList();

      final normalizedName = facultyName?.trim().toLowerCase();
      final filtered = all.where((m) {
        if (facultyUid != null && facultyUid.isNotEmpty && m.facultyUid == facultyUid) {
          return true;
        }
        if (normalizedName != null && normalizedName.isNotEmpty) {
          final target = m.facultyName.toLowerCase();
          if (target.contains(normalizedName) || normalizedName.contains(target)) {
            return true;
          }
        }
        return false;
      }).toList();

      final result = filtered.isNotEmpty ? filtered : all;
      final seen = <String>{};
      final unique = result.where((m) => seen.add(m.id)).toList();
      unique.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.requestedAt.compareTo(a.requestedAt);
      });
      return unique;
    });
  }

  /// Returns all meetings across the entire institution (admin view).
  Future<List<Meeting>> getAllMeetings() async {
    final db = _db;
    if (db == null) return [];
    try {
      final snap = await db.collection(_collection).get();
      final list = snap.docs.map((doc) => Meeting.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.requestedAt.compareTo(a.requestedAt);
      });
      return list;
    } catch (e) {
      debugPrint('❌ Error getting all meetings: $e');
      return [];
    }
  }

  Future<Meeting?> getMeetingById(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final doc = await db.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Meeting.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error getting meeting by ID: $e');
      return null;
    }
  }

  Future<List<Meeting>> getMeetingsByStatus(MeetingStatus status) async {
    final all = await getMeetings();
    return all.where((m) => m.status == status).toList();
  }

  // ── student actions ───────────────────────────────────────────────────────

  /// Creates and persists a new meeting request in Firestore under the currently logged-in
  /// student's UID. Also fires notifications.
  Future<Meeting> submitMeetingRequest({
    required String facultyName,
    required String facultyDept,
    required String purpose,
    String? staffUsername,
    String? facultyUid,
    String? facultyEmail,
    DateTime? meetingDate,
  }) async {
    final db = _db;
    if (db == null) {
      throw StateError('Database connection unavailable.');
    }

    final user = await _authService.getCurrentUser();
    final fbUser = _auth?.currentUser;
    final studentUid = user?.uid ?? fbUser?.uid ?? '';
    final studentName = user?.displayName ?? fbUser?.displayName ?? 'Student';
    final studentUsername = user?.username ??
        (user?.email != null ? user!.email.split('@').first : 'student');
    final studentEmail = user?.email ?? fbUser?.email ?? '';

    final docRef = db.collection(_collection).doc();
    final now = DateTime.now();

    final newMeeting = Meeting(
      id: docRef.id,
      facultyName: facultyName,
      facultyDept: facultyDept,
      purpose: purpose,
      status: MeetingStatus.pending,
      cardColorValue: _pickColor(now.millisecondsSinceEpoch ~/ 1000),
      requestedAt: DateFormat('d MMM, h:mm a').format(now),
      isPinned: false,
      studentName: studentName,
      studentUid: studentUid,
      studentEmail: studentEmail,
      facultyUid: facultyUid,
      facultyEmail: facultyEmail,
      meetingDate: meetingDate ?? now,
      createdAt: now,
    );

    // Save to Firestore!
    await docRef.set(newMeeting.toFirestore());

    // Fire notifications
    try {
      await _notifications.onMeetingRequested(
        studentUsername: studentUsername,
        studentDisplayName: studentName,
        staffUsername: staffUsername ?? 'staff',
        meeting: newMeeting,
      );
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }

    // Fire FCM push notification to staff
    try {
      await _pushNotifications.sendMeetingBookedPushNotification(
        meeting: newMeeting,
        studentName: studentName,
      );
    } catch (e) {
      debugPrint('⚠️ Push notification error on submit: $e');
    }

    return newMeeting;
  }

  /// Appends or updates a meeting document in Firestore.
  Future<void> saveMeeting(Meeting meeting) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection(_collection)
        .doc(meeting.id)
        .set(meeting.toFirestore(), SetOptions(merge: true));
  }

  /// Toggles the pinned status of a meeting in Firestore.
  Future<void> togglePin(String meetingId, bool isPinned) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_collection).doc(meetingId).update({
        'isPinned': isPinned,
      });
    } catch (e) {
      debugPrint('❌ Error toggling pin in Firestore: $e');
    }
  }

  // ── staff actions ─────────────────────────────────────────────────────────

  /// Accepts a meeting request.
  Future<void> acceptMeeting(
    String meetingId, {
    String? studentUsername,
    String? time,
    String? location,
  }) async {
    final db = _db;
    if (db == null) return;

    final updates = <String, dynamic>{
      'status': MeetingStatus.accepted.name,
      'denialReason': 'Accepted by faculty',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (time != null && time.trim().isNotEmpty) updates['time'] = time.trim();
    if (location != null && location.trim().isNotEmpty) {
      updates['location'] = location.trim();
    }

    await db.collection(_collection).doc(meetingId).update(updates);

    final meeting = await getMeetingById(meetingId);
    if (meeting == null) return;

    final staffUser = await _authService.getCurrentUser();
    final staffDisplayName = staffUser?.displayName ?? 'Faculty';
    try {
      await _notifications.onMeetingAccepted(
        studentUsername: studentUsername ?? _usernameFromMeeting(meeting),
        staffDisplayName: staffDisplayName,
        meeting: meeting,
      );
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }

    // Fire FCM push notification to student
    try {
      await _pushNotifications.sendMeetingAcceptedPushNotification(
        meeting: meeting,
        staffName: staffDisplayName,
        time: time,
        location: location,
      );
    } catch (e) {
      debugPrint('⚠️ Push notification error on accept: $e');
    }
  }

  /// Rejects a meeting request with an optional [reason].
  Future<void> rejectMeeting(
    String meetingId, {
    String? studentUsername,
    String? reason,
  }) async {
    final db = _db;
    if (db == null) return;

    await db.collection(_collection).doc(meetingId).update({
      'status': MeetingStatus.rejected.name,
      'denialReason': reason ?? 'Rejected by faculty',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final meeting = await getMeetingById(meetingId);
    if (meeting == null) return;

    final staffUser = await _authService.getCurrentUser();
    final staffDisplayName = staffUser?.displayName ?? 'Faculty';
    try {
      await _notifications.onMeetingRejected(
        studentUsername: studentUsername ?? _usernameFromMeeting(meeting),
        staffDisplayName: staffDisplayName,
        meeting: meeting,
      );
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }

    // Fire FCM push notification to student
    try {
      await _pushNotifications.sendMeetingRejectedPushNotification(
        meeting: meeting,
        staffName: staffDisplayName,
        reason: reason,
      );
    } catch (e) {
      debugPrint('⚠️ Push notification error on reject: $e');
    }
  }

  /// Marks a meeting as completed.
  Future<void> completeMeeting(String meetingId) async {
    final db = _db;
    if (db == null) return;
    await db.collection(_collection).doc(meetingId).update({
      'status': MeetingStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates status and optional denial reason in Firestore.
  Future<void> updateMeetingStatus(
    String meetingId,
    MeetingStatus status, [
    String? reason,
  ]) async {
    final db = _db;
    if (db == null) return;
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null) updates['denialReason'] = reason;
    await db.collection(_collection).doc(meetingId).update(updates);
  }

  /// Edits the time and/or venue of an accepted meeting.
  Future<void> editMeetingDetails(
    String meetingId, {
    String? time,
    String? location,
  }) async {
    final db = _db;
    if (db == null) return;
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (time != null) {
      updates['time'] = time.trim().isEmpty ? null : time.trim();
    }
    if (location != null) {
      updates['location'] = location.trim().isEmpty ? null : location.trim();
    }
    await db.collection(_collection).doc(meetingId).update(updates);
  }

  /// Permanently deletes a meeting from Firestore.
  Future<void> deleteMeeting(String meetingId) async {
    final db = _db;
    if (db == null) return;
    await db.collection(_collection).doc(meetingId).delete();
  }

  // ── internal ──────────────────────────────────────────────────────────────

  /// Derives a best-guess student username from the meeting's [studentName].
  String _usernameFromMeeting(Meeting meeting) {
    final name = meeting.studentName;
    if (name == null || name.isEmpty || name == 'Student') return 'student';
    return name.trim().split(' ').first.toLowerCase();
  }
}
