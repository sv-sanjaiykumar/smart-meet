import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../frontend/student/models/meeting.dart';
import 'auth_service.dart';
import 'fcm_credentials.dart';

/// Top-level background message handler required by Firebase Cloud Messaging.
/// Must be outside of any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint(
    '🔔 [FCM Background] Received message: ${message.messageId} | ${message.notification?.title}',
  );
}

/// Service that coordinates Firebase Cloud Messaging (FCM) push notifications
/// for Smart Meet across background, terminated, and foreground states.
///
/// Features:
/// - WhatsApp-style heads-up alert banner (channel: Importance.max, Priority.high).
/// - Saves user device tokens to Firestore `users/{uid}`.
/// - Subscribes devices to user-specific and role-specific FCM topics.
/// - Directly sends FCM messages via Google FCM HTTP v1 API with service account auth.
/// - Shows instant heads-up banner in the foreground via FlutterLocalNotifications.
class PushNotificationService {
  PushNotificationService.custom({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? db,
  })  : _injectedMessaging = messaging,
        _injectedLocalNotifications = localNotifications,
        _injectedDb = db;

  static final PushNotificationService _instance =
      PushNotificationService.custom();

  factory PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? db,
  }) {
    if (messaging != null || localNotifications != null || db != null) {
      return PushNotificationService.custom(
        messaging: messaging,
        localNotifications: localNotifications,
        db: db,
      );
    }
    return _instance;
  }

  final FirebaseMessaging? _injectedMessaging;
  final FlutterLocalNotificationsPlugin? _injectedLocalNotifications;
  final FirebaseFirestore? _injectedDb;

  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;

  FlutterLocalNotificationsPlugin get _localNotifications =>
      _injectedLocalNotifications ?? FlutterLocalNotificationsPlugin();

  FirebaseFirestore? get _db {
    if (_injectedDb != null) return _injectedDb;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ── Channel Constants ──────────────────────────────────────────────────────
  static const String channelId = 'smart_meet_high_importance';
  static const String channelName = 'Smart Meet Notifications';
  static const String channelDescription =
      'High-priority heads-up notifications for meeting requests and updates';

  bool _isInitialized = false;
  String? _currentToken;
  String? _currentUserId;

  String? get currentToken => _currentToken;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initializes FCM listeners, creates the Android high-importance notification
  /// channel, configures foreground presentation, and requests user permissions.
  Future<void> initialize({
    void Function(RemoteMessage)? onNotificationOpened,
  }) async {
    if (_isInitialized) return;

    try {
      // 1. Request notification permissions from user
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: true,
        );
        debugPrint(
          '🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}',
        );
      } catch (e) {
        debugPrint('⚠️ [FCM] requestPermission error: $e');
      }

      // 2. Setup Android high-importance notification channel
      try {
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        final androidImpl =
            _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(androidChannel);
          await androidImpl.requestNotificationsPermission();
        }
      } catch (e) {
        debugPrint('⚠️ [FCM] Android channel setup error: $e');
      }

      // 3. Initialize FlutterLocalNotificationsPlugin
      try {
        const initSettingsAndroid = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initSettingsDarwin = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: initSettingsAndroid,
          iOS: initSettingsDarwin,
          macOS: initSettingsDarwin,
        );

        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (response) {
            debugPrint(
              '🔔 [LocalNotification] Tapped notification payload: ${response.payload}',
            );
          },
        );
      } catch (e) {
        debugPrint('⚠️ [FCM] localNotifications.initialize error: $e');
      }

      // 4. Set iOS foreground notification presentation options
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // 5. Handle foreground notifications (WhatsApp-style heads-up alert)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}',
        );
        _handleForegroundMessage(message);
      });

      // 6. Handle notification click when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [FCM Open] User tapped notification: ${message.data}',
        );
        onNotificationOpened?.call(message);
      });

      // 7. Check if app was opened from a terminated state via notification
      try {
        final initialMessage = await _messaging.getInitialMessage().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        if (initialMessage != null) {
          debugPrint(
            '🔔 [FCM Initial] App launched from terminated state via notification: ${initialMessage.data}',
          );
          onNotificationOpened?.call(initialMessage);
        }
      } catch (e) {
        debugPrint('ℹ️ [FCM] getInitialMessage bypassed: $e');
      }

      // 8. Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        if (_currentUserId != null) {
          _persistTokenToFirestore(_currentUserId!, newToken);
        }
      });

      _isInitialized = true;
      debugPrint('✅ [FCM] PushNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error initializing PushNotificationService: $e');
    }
  }

  // ── Foreground Notification Display ────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Smart Meet';
    final body = notification?.body ?? message.data['body'] ?? '';

    showHeadsUpNotification(
      title: title,
      body: body,
      data: message.data,
      id: message.hashCode,
    );
  }

  /// Displays a WhatsApp-style heads up notification banner on top of the screen
  /// with sound and high-priority vibration.
  Future<void> showHeadsUpNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: title,
        showWhen: true,
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: 'Smart Meet',
        ),
        color: const Color(0xFF137FEC),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: false,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final notifId = id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      debugPrint('⚠️ [FCM] Error showing heads-up notification: $e');
    }
  }

  // ── Device Registration & Token Management ─────────────────────────────────

  /// Registers the current device's FCM token in Firestore under `users/{uid}`
  /// and subscribes to user-specific and role-specific FCM topics.
  Future<String?> registerUserDevice(
    String uid, {
    UserRole? role,
    String? username,
  }) async {
    _currentUserId = uid;
    try {
      String? token;
      try {
        token = await _messaging.getToken().timeout(
          const Duration(seconds: 4),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint(
          'ℹ️ [FCM] Device token not available yet (normal on iOS Simulator): $e',
        );
      }

      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _persistTokenToFirestore(uid, token);

        // Subscribe to user personal topic
        try {
          await _messaging.subscribeToTopic('user_$uid').timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );

          // Subscribe to role topic (student or staff)
          if (role != null) {
            await _messaging.subscribeToTopic('role_${role.name}').timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
          }

          // Subscribe to sanitized username topic if provided
          if (username != null && username.trim().isNotEmpty) {
            final clean = username
                .trim()
                .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
                .toLowerCase();
            await _messaging.subscribeToTopic('user_name_$clean').timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
          }
        } catch (_) {}

        debugPrint(
          '✅ [FCM] Device token registered for uid: $uid (token: ${token.substring(0, 12)}...)',
        );
        return token;
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Error registering device token for $uid: $e');
    }
    return null;
  }

  Future<void> _persistTokenToFirestore(String uid, String token) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [FCM] Error persisting token to Firestore: $e');
    }
  }

  /// Removes the device token on logout and unsubscribes from topics.
  Future<void> unregisterUserDevice(String uid) async {
    try {
      final token = _currentToken ?? await _messaging.getToken();
      if (token != null) {
        final db = _db;
        if (db != null) {
          await db.collection('users').doc(uid).update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
        }
        await _messaging.unsubscribeFromTopic('user_$uid');
      }
      _currentUserId = null;
    } catch (e) {
      debugPrint('⚠️ [FCM] Error unregistering user device: $e');
    }
  }

  // ── FCM HTTP v1 Dispatching ────────────────────────────────────────────────

  /// Obtains a short-lived Google OAuth2 access token for FCM v1 messaging.
  Future<String?> _getOAuth2AccessToken() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(
        FcmCredentials.serviceAccountMap,
      );
      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      debugPrint('⚠️ [FCM] Failed to authenticate service account: $e');
      return null;
    }
  }

  /// Sends a push notification via Google Firebase Cloud Messaging HTTP v1 API.
  Future<bool> sendFcmMessage({
    String? targetToken,
    String? targetTopic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (targetToken == null && targetTopic == null) {
      debugPrint('⚠️ [FCM] Either targetToken or targetTopic must be provided.');
      return false;
    }

    final accessToken = await _getOAuth2AccessToken();
    if (accessToken == null) {
      debugPrint('⚠️ [FCM] No OAuth2 access token; skipping HTTP v1 dispatch.');
      return false;
    }

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/${FcmCredentials.projectId}/messages:send',
    );

    final messagePayload = <String, dynamic>{
      'token': ?targetToken,
      if (targetTopic != null && targetToken == null) 'topic': targetTopic,
      'notification': {
        'title': title,
        'body': body,
      },
      if (data != null && data.isNotEmpty) 'data': data,
      'android': {
        'priority': 'HIGH',
        'notification': {
          'channel_id': channelId,
          'default_sound': true,
          'default_vibrate_timings': true,
          'notification_priority': 'PRIORITY_MAX',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      'apns': {
        'headers': {
          'apns-priority': '10',
        },
        'payload': {
          'aps': {
            'alert': {
              'title': title,
              'body': body,
            },
            'sound': 'default',
            'badge': 1,
            'content-available': 1,
          },
        },
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'message': messagePayload}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('🚀 [FCM] Push sent successfully: "$title"');
        return true;
      } else {
        debugPrint(
          '❌ [FCM] Send failed: status=${response.statusCode}, response=${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [FCM] HTTP error sending push: $e');
      return false;
    }
  }

  // ── Domain-Specific Notification Triggers ──────────────────────────────────

  /// Resolves device tokens for a given user UID from Firestore.
  Future<List<String>> _getUserTokens(String uid) async {
    final db = _db;
    if (db == null || uid.isEmpty) return [];
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (!doc.exists) return [];
      final data = doc.data() ?? {};
      final tokens = <String>{};
      final single = data['fcmToken'] as String?;
      if (single != null && single.isNotEmpty) tokens.add(single);
      final array = data['fcmTokens'] as List<dynamic>?;
      if (array != null) {
        for (final item in array) {
          if (item is String && item.isNotEmpty) tokens.add(item);
        }
      }
      return tokens.toList();
    } catch (e) {
      debugPrint('⚠️ [FCM] Error getting user tokens for $uid: $e');
      return [];
    }
  }

  /// Finds a user document ID by displayName, username, or email.
  Future<String?> _findUserId({
    String? displayName,
    String? username,
    String? email,
  }) async {
    final db = _db;
    if (db == null) return null;
    try {
      if (email != null && email.isNotEmpty) {
        final snap = await db
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase().trim())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      if (username != null && username.isNotEmpty) {
        final snap = await db
            .collection('users')
            .where('username', isEqualTo: username.toLowerCase().trim())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
      if (displayName != null && displayName.isNotEmpty) {
        final snap = await db
            .collection('users')
            .where('displayName', isEqualTo: displayName.trim())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first.id;
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Error finding user ID: $e');
    }
    return null;
  }

  /// Sends a push notification to staff when a student books a meeting.
  ///
  /// WhatsApp-style:
  /// Title: "New Meeting Request 📅"
  /// Body: "$studentName requested a meeting for \"$purpose\"."
  Future<void> sendMeetingBookedPushNotification({
    required Meeting meeting,
    required String studentName,
  }) async {
    final title = 'New Meeting Request 📅';
    final body = '$studentName requested a meeting for "${meeting.purpose}".';
    final data = {
      'type': 'new_meeting_request',
      'meetingId': meeting.id,
      'studentName': studentName,
      'purpose': meeting.purpose,
      'facultyName': meeting.facultyName,
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    // 1. Resolve staff UID
    var staffUid = meeting.facultyUid;
    if (staffUid == null || staffUid.isEmpty) {
      staffUid = await _findUserId(
        displayName: meeting.facultyName,
        email: meeting.facultyEmail,
      );
    }

    bool sentAny = false;

    if (staffUid != null && staffUid.isNotEmpty) {
      final tokens = await _getUserTokens(staffUid);
      for (final token in tokens) {
        final success = await sendFcmMessage(
          targetToken: token,
          title: title,
          body: body,
          data: data,
        );
        if (success) sentAny = true;
      }

      // Also dispatch to staff's personal user topic
      await sendFcmMessage(
        targetTopic: 'user_$staffUid',
        title: title,
        body: body,
        data: data,
      );
    }

    // Also broadcast to staff role topic so all logged-in staff instances are aware
    await sendFcmMessage(
      targetTopic: 'role_staff',
      title: title,
      body: body,
      data: data,
    );

    // When testing or on simulator, also trigger the heads-up notification
    // banner on the current screen so the WhatsApp-style popup is immediately visible.
    if (_currentUserId == staffUid || staffUid == null || kDebugMode || !sentAny) {
      await showHeadsUpNotification(
        title: title,
        body: body,
        data: data,
      );
    }

    debugPrint(
      '🔔 [FCM] Meeting request push dispatched: staffUid=$staffUid (sentToTokens=$sentAny)',
    );
  }

  /// Sends a push notification to the student when a staff member accepts their meeting.
  ///
  /// WhatsApp-style:
  /// Title: "Meeting Accepted! 🎉"
  /// Body: "$staffName accepted your \"$purpose\" request. Time: $time · Venue: $location"
  Future<void> sendMeetingAcceptedPushNotification({
    required Meeting meeting,
    required String staffName,
    String? time,
    String? location,
  }) async {
    final detailsList = <String>[];
    final finalTime = time ?? meeting.time;
    final finalLoc = location ?? meeting.location;
    if (finalTime != null && finalTime.trim().isNotEmpty) {
      detailsList.add('Time: ${finalTime.trim()}');
    }
    if (finalLoc != null && finalLoc.trim().isNotEmpty) {
      detailsList.add('Venue: ${finalLoc.trim()}');
    }
    final detailsStr =
        detailsList.isNotEmpty ? ' (${detailsList.join(" · ")})' : '';

    final title = 'Meeting Accepted! 🎉';
    final body =
        '$staffName accepted your "${meeting.purpose}" request.$detailsStr';

    final data = {
      'type': 'meeting_accepted',
      'meetingId': meeting.id,
      'staffName': staffName,
      'purpose': meeting.purpose,
      'time': finalTime ?? '',
      'location': finalLoc ?? '',
      'status': 'accepted',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    // 1. Resolve student UID
    var studentUid = meeting.studentUid;
    if (studentUid == null || studentUid.isEmpty) {
      studentUid = await _findUserId(
        displayName: meeting.studentName,
        email: meeting.studentEmail,
      );
    }

    bool sentAny = false;

    if (studentUid != null && studentUid.isNotEmpty) {
      final tokens = await _getUserTokens(studentUid);
      for (final token in tokens) {
        final success = await sendFcmMessage(
          targetToken: token,
          title: title,
          body: body,
          data: data,
        );
        if (success) sentAny = true;
      }

      // Also dispatch to student's personal user topic
      await sendFcmMessage(
        targetTopic: 'user_$studentUid',
        title: title,
        body: body,
        data: data,
      );
    }

    // When testing or on simulator, also trigger the heads-up notification
    // banner on the current screen so the WhatsApp-style popup is immediately visible.
    if (_currentUserId == studentUid || studentUid == null || kDebugMode || !sentAny) {
      await showHeadsUpNotification(
        title: title,
        body: body,
        data: data,
      );
    }

    debugPrint(
      '🔔 [FCM] Meeting accepted push dispatched: studentUid=$studentUid (sentToTokens=$sentAny)',
    );
  }

  /// Sends a push notification to student when staff declines a meeting request.
  Future<void> sendMeetingRejectedPushNotification({
    required Meeting meeting,
    required String staffName,
    String? reason,
  }) async {
    final title = 'Meeting Declined';
    final reasonStr = (reason != null && reason.trim().isNotEmpty)
        ? ' Reason: ${reason.trim()}'
        : '';
    final body =
        '$staffName declined your "${meeting.purpose}" request.$reasonStr';

    final data = {
      'type': 'meeting_rejected',
      'meetingId': meeting.id,
      'staffName': staffName,
      'purpose': meeting.purpose,
      'reason': reason ?? '',
      'status': 'rejected',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    var studentUid = meeting.studentUid;
    if (studentUid == null || studentUid.isEmpty) {
      studentUid = await _findUserId(
        displayName: meeting.studentName,
        email: meeting.studentEmail,
      );
    }

    if (studentUid != null && studentUid.isNotEmpty) {
      final tokens = await _getUserTokens(studentUid);
      for (final token in tokens) {
        await sendFcmMessage(
          targetToken: token,
          title: title,
          body: body,
          data: data,
        );
      }
      await sendFcmMessage(
        targetTopic: 'user_$studentUid',
        title: title,
        body: body,
        data: data,
      );
    }

    if (_currentUserId == studentUid || studentUid == null) {
      await showHeadsUpNotification(
        title: title,
        body: body,
        data: data,
      );
    }
  }
}

