/// Represents a notification stored and displayed within Smart Meet.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? meetingId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.meetingId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    meetingId: meetingId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.index,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isRead': isRead,
    'meetingId': meetingId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values[json['type'] as int],
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int,
        ),
        isRead: json['isRead'] as bool? ?? false,
        meetingId: json['meetingId'] as String?,
      );
}

/// The category of a notification.
enum NotificationType {
  /// A new meeting request was submitted by a student (shown to staff).
  newRequest,

  /// A meeting was accepted by the faculty (shown to student).
  accepted,

  /// A meeting was rejected/cancelled by the faculty (shown to student).
  rejected,

  /// A general system update (shown to all users).
  system,

  /// A reminder about an upcoming accepted meeting.
  reminder,
}
