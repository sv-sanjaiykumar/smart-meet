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
  final Color cardColor;
  final bool isPinned;
  final String requestedAt;
  final String? denialReason;

  Meeting({
    required this.id,
    required this.facultyName,
    required this.facultyDept,
    required this.purpose,
    this.time,
    this.location,
    required this.status,
    required this.cardColor,
    this.isPinned = false,
    required this.requestedAt,
    this.denialReason,
  });
}

final List<Meeting> dummyMeetings = [
  Meeting(
    id: '1',
    facultyName: 'Prof. Lakshmanan',
    facultyDept: 'Dept of CSE',
    purpose: 'Project discussion - reg.',
    time: '12:30 Pm',
    location: 'TF-23',
    status: MeetingStatus.accepted,
    cardColor: const Color(0xFFBFE0FC),
    isPinned: true,
    requestedAt: '23rd July, 2025 - 2:14 PM',
  ),
  Meeting(
    id: '2',
    facultyName: 'Dr. Anitha',
    facultyDept: 'Dept of ECE',
    purpose: 'Internship Guidance',
    time: '02:00 Pm',
    location: 'SF-10',
    status: MeetingStatus.pending,
    cardColor: const Color(0xFFE4C7FF),
    requestedAt: '24th July, 2025 - 10:00 AM',
  ),
  // Data for Requests Page
  Meeting(
    id: 'req1',
    facultyName: 'Prof Thoufik Umar',
    facultyDept: 'Dept of CSE',
    purpose: 'Regarding Academic doubts',
    requestedAt: '23rd July, 2025 - 2:14 PM.',
    status: MeetingStatus.completed,
    cardColor: const Color(0xFFF3F7FF),
    time: '11 - 11:20 AM',
    location: 'TF-03',
    isPinned: true,
  ),
  Meeting(
    id: 'req2',
    facultyName: 'Prof Praveen Kumar',
    facultyDept: 'Dept of CSE',
    purpose: 'Sick Leave Certificate Submission',
    requestedAt: '23rd July, 2025 - 3:00 PM.',
    status: MeetingStatus.completed,
    cardColor: Colors.white,
  ),
  Meeting(
    id: 'req3',
    facultyName: 'Prof Alexa Maryam',
    facultyDept: 'Dept of CSE',
    purpose: 'Regarding Academic doubts',
    requestedAt: '23rd July, 2025 - 2:14 PM.',
    status: MeetingStatus.accepted,
    cardColor: const Color(0xFFF2FFF3),
    time: '11 - 11:20 AM',
    location: 'TF-03',
    isPinned: true,
  ),
  Meeting(
    id: 'req4',
    facultyName: 'Prof Saravanan',
    facultyDept: 'Dept of CSE',
    purpose: 'Regarding Academic doubts',
    requestedAt: 'Aug 08, 2:15 PM',
    status: MeetingStatus.rejected,
    cardColor: const Color(0xFFFFFBFA),
    denialReason: 'Busy due to paper works - Aug 07, 3 PM',
    isPinned: true,
  ),
];
