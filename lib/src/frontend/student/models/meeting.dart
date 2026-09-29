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
  });

  Color get cardColor => Color(cardColorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'facultyName': facultyName,
    'facultyDept': facultyDept,
    'purpose': purpose,
    'time': time,
    'location': location,
    'status': status.index,
    'cardColorValue': cardColorValue,
    'isPinned': isPinned,
    'requestedAt': requestedAt,
    'denialReason': denialReason,
    'studentName': studentName,
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'],
    facultyName: json['facultyName'],
    facultyDept: json['facultyDept'],
    purpose: json['purpose'],
    time: json['time'],
    location: json['location'],
    status: MeetingStatus.values[json['status'] as int],
    cardColorValue: json['cardColorValue'] as int,
    isPinned: json['isPinned'] ?? false,
    requestedAt: json['requestedAt'],
    denialReason: json['denialReason'],
    studentName: json['studentName'],
  );
}
