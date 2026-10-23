import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/meeting_service.dart';
import '../../student/models/meeting.dart';
import 'staff_history_page.dart';
import 'staff_notifications_page.dart';
import 'staff_profile_page.dart';
import 'staff_requests_page.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  final MeetingService _meetingService = MeetingService();
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final meetings = await _meetingService.getMeetings();
    if (!mounted) return;
    setState(() {
      _meetings = meetings;
      _isLoading = false;
    });
  }

  Future<void> _updateMeetingStatus(
    Meeting meeting,
    MeetingStatus status,
  ) async {
    if (status == MeetingStatus.accepted) {
      await _meetingService.acceptMeeting(meeting.id);
    } else if (status == MeetingStatus.rejected) {
      await _meetingService.rejectMeeting(meeting.id);
    } else {
      await _meetingService.completeMeeting(meeting.id);
    }
    await _loadMeetings();
  }

  Future<void> _editReminder(Meeting meeting) async {
    var updatedTime = meeting.time ?? '';
    var updatedLocation = meeting.location ?? '';
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('reminder-time'),
              initialValue: updatedTime,
              onChanged: (value) => updatedTime = value,
              decoration: const InputDecoration(labelText: 'Meeting time'),
            ),
            TextFormField(
              key: const ValueKey('reminder-location'),
              initialValue: updatedLocation,
              onChanged: (value) => updatedLocation = value,
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await _meetingService.editMeetingDetails(
        meeting.id,
        time: updatedTime.trim().isEmpty ? null : updatedTime.trim(),
        location: updatedLocation.trim().isEmpty ? null : updatedLocation.trim(),
      );
      await _loadMeetings();
    }
  }

  String _currentDateLabel() {
    final now = DateTime.now();
    final day = now.day;
    final suffix = switch (day % 10) {
      1 => day == 11 ? 'th' : 'st',
      2 => day == 12 ? 'th' : 'nd',
      3 => day == 13 ? 'th' : 'rd',
      _ => 'th',
    };
    return '${day}$suffix ${DateFormat.MMMM().format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final upcomingMeetings = _meetings
        .where(
          (meeting) =>
              meeting.status == MeetingStatus.accepted ||
              meeting.status == MeetingStatus.pending,
        )
        .toList();
    final pendingRequests = _meetings
        .where((meeting) => meeting.status == MeetingStatus.pending)
        .toList();

    return Scaffold(
      backgroundColor: _selectedTab == 4
          ? Colors.white
          : const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedTab == 2
            ? StaffHistoryPage(meetings: _meetings, onRefresh: _loadMeetings)
            : _selectedTab == 3
            ? StaffNotificationsPage(
                meetings: _meetings,
                onRefresh: _loadMeetings,
                onBack: () => setState(() => _selectedTab = 0),
                onEditReminder: _editReminder,
              )
            : _selectedTab == 4
            ? StaffProfilePage(onBack: () => setState(() => _selectedTab = 0))
            : _selectedTab == 1
            ? StaffRequestsPage(
                meetings: _meetings,
                onRefresh: _loadMeetings,
                onStatusChanged: _updateMeetingStatus,
              )
            : RefreshIndicator(
                onRefresh: _loadMeetings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu,
                            size: 28,
                            color: Colors.black87,
                          ),
                          Text(
                            _currentDateLabel(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(
                            Icons.settings_outlined,
                            size: 26,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8BC5D9),
                                    Color(0xFFE4E9EE),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFB9D4EA),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    height: 1.25,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Hello Miss Anushka,\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Ready for 4 meetings today!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Today's meetings",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (upcomingMeetings.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'No meetings yet. New student requests will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      else
                        SizedBox(
                          height: 156,
                          child: PageView.builder(
                            itemCount: upcomingMeetings.length,
                            padEnds: false,
                            controller: PageController(viewportFraction: 0.92),
                            itemBuilder: (context, index) {
                              final meeting = upcomingMeetings[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFB5C8FF),
                                      const Color(0xFFE9EDFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          meeting.studentName ?? 'Student',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.edit_note,
                                          size: 24,
                                          color: Colors.black87,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${meeting.facultyDept.toLowerCase()} • ${meeting.purpose}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.35,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              meeting.location ?? 'TF 03',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              meeting.time ?? '11:35 AM',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Requests',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selectedTab = 1),
                            child: const Text(
                              'view all',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4C8DF7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _filterChip('Pending', isSelected: true),
                          const SizedBox(width: 12),
                          _filterChip('New'),
                          const SizedBox(width: 12),
                          _filterChip('Urgent'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (pendingRequests.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'No pending requests',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingRequests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final meeting = pendingRequests[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFE9D8C8),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.black87,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              meeting.studentName ?? 'Student',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF2FF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                meeting.facultyDept
                                                    .replaceAll('Dept of ', '')
                                                    .toLowerCase(),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => _updateMeetingStatus(
                                                meeting,
                                                MeetingStatus.rejected,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 22,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          meeting.purpose,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              meeting.id
                                                  .replaceAll('req_', '')
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.black54,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  meeting.time ??
                                                      'Set time & venue',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _updateMeetingStatus(
                                                  meeting,
                                                  MeetingStatus.accepted,
                                                ),
                                            icon: const Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'slide to accept',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF4C8DF7,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(0, Icons.home_outlined, 'Home'),
            _buildNavButton(1, Icons.calendar_month_outlined, 'Requests'),
            _buildNavButton(2, Icons.history, 'History'),
            _buildNavButton(3, Icons.notifications_none, 'Notifications'),
            _buildNavButton(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    return IconButton(
      tooltip: label,
      onPressed: () {
        if (index >= 0 && index <= 4) {
          setState(() => _selectedTab = index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label is not available yet')),
          );
        }
      },
      icon: Icon(icon, size: index == 2 ? 34 : 26),
    );
  }

  Widget _filterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFB9CFFF) : const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (isSelected) const SizedBox(width: 6),
          if (isSelected) const Icon(Icons.check, size: 16),
        ],
      ),
    );
  }
}
