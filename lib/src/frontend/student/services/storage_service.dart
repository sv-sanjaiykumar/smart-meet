import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting.dart';

class StorageService {
  static const String _key = 'smart_meet_meetings';

  Future<void> saveMeetings(List<Meeting> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(meetings.map((m) => m.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<List<Meeting>> getMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_key);
    
    if (encoded == null) {
      return _getInitialData();
    }

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((item) => Meeting.fromJson(item)).toList();
  }

  List<Meeting> _getInitialData() {
    return [
      Meeting(
        id: '1',
        facultyName: 'Prof. Lakshmanan',
        facultyDept: 'Dept of CSE',
        purpose: 'Project discussion - reg.',
        time: '12:30 Pm',
        location: 'TF-23',
        status: MeetingStatus.accepted,
        cardColorValue: 0xFFBFE0FC,
        isPinned: true,
        requestedAt: '23rd July, 2025 - 2:14 PM',
      ),
      Meeting(
        id: 'req1',
        facultyName: 'Prof Thoufik Umar',
        facultyDept: 'Dept of CSE',
        purpose: 'Regarding Academic doubts',
        requestedAt: '23rd July, 2025 - 2:14 PM.',
        status: MeetingStatus.completed,
        cardColorValue: 0xFFF3F7FF,
        time: '11 - 11:20 AM',
        location: 'TF-03',
        isPinned: true,
      ),
      Meeting(
        id: 'req3',
        facultyName: 'Prof Alexa Maryam',
        facultyDept: 'Dept of CSE',
        purpose: 'Regarding Academic doubts',
        requestedAt: '23rd July, 2025 - 2:14 PM.',
        status: MeetingStatus.accepted,
        cardColorValue: 0xFFF2FFF3,
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
        cardColorValue: 0xFFFFFBFA,
        denialReason: 'Busy due to paper works - Aug 07, 3 PM',
        isPinned: true,
      ),
    ];
  }
}
