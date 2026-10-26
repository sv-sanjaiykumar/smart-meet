import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MeetingStatus { accepted, rejected, pending, completed }

class Meeting {
  final String id;
  final String facultyName;
  final String facultyDept;
  final String purpose;
  final String? time;
  final String? location;
  final MeetingStatus status;
  final int cardColorValue;
  final bool isPinned;
  final String requestedAt;
  final String? denialReason;
  final String? studentName;
  final String? studentUid;
  final String? studentEmail;
  final String? facultyUid;
  final String? facultyEmail;
  final DateTime? meetingDate;
  final DateTime? createdAt;

  Meeting({
    required this.id,
    required this.facultyName,
    required this.facultyDept,
    required this.purpose,
    this.time,
    this.location,
    required this.status,
    required this.cardColorValue,
    this.isPinned = false,
    required this.requestedAt,
    this.denialReason,
    this.studentName,
    this.studentUid,
    this.studentEmail,
    this.facultyUid,
    this.facultyEmail,
    this.meetingDate,
    this.createdAt,
  });

  Color get cardColor => Color(cardColorValue);

  static MeetingStatus parseStatus(dynamic val) {
    if (val is int && val >= 0 && val < MeetingStatus.values.length) {
      return MeetingStatus.values[val];
    }
    if (val is String) {
      switch (val.toLowerCase().trim()) {
        case 'accepted':
          return MeetingStatus.accepted;
        case 'rejected':
        case 'denied':
          return MeetingStatus.rejected;
        case 'completed':
          return MeetingStatus.completed;
        case 'pending':
        default:
          return MeetingStatus.pending;
      }
    }
    return MeetingStatus.pending;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'facultyName': facultyName,
    'facultyDept': facultyDept,
    'purpose': purpose,
    'time': time,
    'location': location,
    'status': status.name,
    'cardColorValue': cardColorValue,
    'isPinned': isPinned,
    'requestedAt': requestedAt,
    'denialReason': denialReason,
    'studentName': studentName,
    'studentUid': studentUid,
    'studentEmail': studentEmail,
    'facultyUid': facultyUid,
    'facultyEmail': facultyEmail,
    'meetingDate': meetingDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'facultyName': facultyName,
    'facultyDept': facultyDept,
    'purpose': purpose,
    'time': time,
    'location': location,
    'status': status.name,
    'cardColorValue': cardColorValue,
    'isPinned': isPinned,
    'requestedAt': requestedAt,
    'denialReason': denialReason,
    'studentName': studentName,
    'studentUid': studentUid,
    'studentEmail': studentEmail,
    'facultyUid': facultyUid,
    'facultyEmail': facultyEmail,
    'meetingDate': meetingDate != null ? Timestamp.fromDate(meetingDate!) : null,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'] as String? ?? '',
    facultyName: json['facultyName'] as String? ?? '',
    facultyDept: json['facultyDept'] as String? ?? '',
    purpose: json['purpose'] as String? ?? '',
    time: json['time'] as String?,
    location: json['location'] as String?,
    status: parseStatus(json['status']),
    cardColorValue: json['cardColorValue'] as int? ?? 0xFFE8F4FD,
    isPinned: json['isPinned'] as bool? ?? false,
    requestedAt: json['requestedAt'] as String? ?? '',
    denialReason: json['denialReason'] as String?,
    studentName: json['studentName'] as String?,
    studentUid: json['studentUid'] as String?,
    studentEmail: json['studentEmail'] as String?,
    facultyUid: json['facultyUid'] as String?,
    facultyEmail: json['facultyEmail'] as String?,
    meetingDate: json['meetingDate'] != null
        ? DateTime.tryParse(json['meetingDate'] as String)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Meeting(
      id: doc.id,
      facultyName: data['facultyName'] as String? ?? '',
      facultyDept: data['facultyDept'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      time: data['time'] as String?,
      location: data['location'] as String?,
      status: parseStatus(data['status']),
      cardColorValue: data['cardColorValue'] as int? ?? 0xFFE8F4FD,
      isPinned: data['isPinned'] as bool? ?? false,
      requestedAt: data['requestedAt'] as String? ?? '',
      denialReason: data['denialReason'] as String?,
      studentName: data['studentName'] as String?,
      studentUid: data['studentUid'] as String?,
      studentEmail: data['studentEmail'] as String?,
      facultyUid: data['facultyUid'] as String?,
      facultyEmail: data['facultyEmail'] as String?,
      meetingDate: parseDate(data['meetingDate']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Meeting copyWith({
    String? id,
    String? facultyName,
    String? facultyDept,
    String? purpose,
    String? time,
    String? location,
    MeetingStatus? status,
    int? cardColorValue,
    bool? isPinned,
    String? requestedAt,
    String? denialReason,
    String? studentName,
    String? studentUid,
    String? studentEmail,
    String? facultyUid,
    String? facultyEmail,
    DateTime? meetingDate,
    DateTime? createdAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      facultyName: facultyName ?? this.facultyName,
      facultyDept: facultyDept ?? this.facultyDept,
      purpose: purpose ?? this.purpose,
      time: time ?? this.time,
      location: location ?? this.location,
      status: status ?? this.status,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isPinned: isPinned ?? this.isPinned,
      requestedAt: requestedAt ?? this.requestedAt,
      denialReason: denialReason ?? this.denialReason,
      studentName: studentName ?? this.studentName,
      studentUid: studentUid ?? this.studentUid,
      studentEmail: studentEmail ?? this.studentEmail,
      facultyUid: facultyUid ?? this.facultyUid,
      facultyEmail: facultyEmail ?? this.facultyEmail,
      meetingDate: meetingDate ?? this.meetingDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
