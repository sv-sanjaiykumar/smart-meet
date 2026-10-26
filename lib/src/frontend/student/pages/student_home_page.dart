import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/auth_service.dart';
import '../models/meeting.dart';
import '../services/storage_service.dart';
import '../theme/student_theme.dart';
import 'calendar_page.dart';
import 'add_meeting_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'request_meeting_sheet.dart';
import 'requests_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedTab = 0;
  MeetingStatus _selectedStatus = MeetingStatus.accepted;
  List<Meeting> meetings = [];
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _studentName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final user = await _authService.getCurrentUser();
    final loadedMeetings = await _storageService.getMeetings();
    if (!mounted) return;

    // Pinned meetings first, then newest
    loadedMeetings.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.requestedAt.compareTo(a.requestedAt);
    });

    setState(() {
      _studentName = user?.displayName ?? 'Student';
      meetings = loadedMeetings;
      _isLoading = false;
    });
  }

  Widget _getBody() {
    switch (_selectedTab) {
      case 0:
        return _buildHome(context);
      case 1:
        return const CalendarPage();
      case 2:
        return const AddMeetingPage();
      case 3:
        return const NotificationsPage();
      case 4:
        return ProfilePage(onProfileUpdated: _loadMeetings);
      default:
        return _buildHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _getBody()),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true, // This allows the body to go behind the bottom nav
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home),
              _buildNavItem(1, Icons.assignment_outlined, Icons.assignment),
              _buildNavItem(2, Icons.add, Icons.add),
              _buildNavItem(3, Icons.notifications_none, Icons.notifications),
              _buildNavItem(4, Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          _showRequestSheet(context);
        } else {
          setState(() => _selectedTab = index);
        }
      },
      child: Icon(
        isSelected ? selectedIcon : icon,
        color: StudentColors.ink,
        size: 28,
      ),
    );
  }

  void _showRequestSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RequestMeetingSheet(),
    );

    if (result == true) {
      _loadMeetings(); // Refresh the counts and list on the home page
    }
  }

  Widget _buildHome(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedMeetings = meetings
        .where((meeting) => meeting.status == _selectedStatus)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 28),
            if (selectedMeetings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _emptyStatusMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: StudentColors.mutedInk),
                ),
              )
            else
              ...selectedMeetings.map(
                (meeting) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildMeetingCard(meeting),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final daySuffix = switch (now.day % 10) {
      1 when now.day % 100 != 11 => 'st',
      2 when now.day % 100 != 12 => 'nd',
      3 when now.day % 100 != 13 => 'rd',
      _ => 'th',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RequestsPage()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('MMMM').format(now)} ${now.day}$daySuffix, ${now.year}',
                style: TextStyle(color: StudentColors.mutedInk, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Hey, $_studentName!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Requests status..',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _emptyStatusMessage() => switch (_selectedStatus) {
    MeetingStatus.accepted => 'No accepted meetings yet. Your requests will appear here once faculty responds.',
    MeetingStatus.rejected => 'No rejected meetings yet.',
    MeetingStatus.pending => 'No pending meeting requests.',
    MeetingStatus.completed => 'No completed meetings yet.',
  };

  Widget _buildStats() {
    final acceptedCount = meetings
        .where((m) => m.status == MeetingStatus.accepted)
        .length;
    final rejectedCount = meetings
        .where((m) => m.status == MeetingStatus.rejected)
        .length;
    final pendingCount = meetings
        .where((m) => m.status == MeetingStatus.pending)
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: switch (_selectedStatus) {
                MeetingStatus.accepted => Alignment.centerLeft,
                MeetingStatus.rejected => Alignment.center,
                MeetingStatus.pending => Alignment.centerRight,
                MeetingStatus.completed => Alignment.centerLeft,
              },
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1,
                child: DecoratedBox(
                  key: const ValueKey('student-status-indicator'),
                  decoration: BoxDecoration(
                    color: StudentColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: StudentColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildStatItem(acceptedCount, 'Accepted', MeetingStatus.accepted),
              _buildStatItem(rejectedCount, 'Rejected', MeetingStatus.rejected),
              _buildStatItem(pendingCount, 'Pending', MeetingStatus.pending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label, MeetingStatus status) {
    final isActive = _selectedStatus == status;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label meetings: $count',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            key: ValueKey('student-status-${status.name}'),
            borderRadius: BorderRadius.circular(22),
            onTap: () => setState(() => _selectedStatus = status),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : StudentColors.ink,
                    ),
                    child: Text('$count'),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive ? Colors.white : StudentColors.mutedInk,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: meeting.cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/meeting facutly assest-01.png',
                key: ValueKey('meeting-illustration-${meeting.id}'),
                width: 170,
                height: 170,
                fit: BoxFit.contain,
                semanticLabel: 'Student studying illustration',
              ),
            ),
          ),
          // Location Badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: StudentColors.primary,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meeting.location ?? 'TBD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Glassmorphic Details Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: StudentColors.primary.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Meeting with\n${meeting.facultyName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await _storageService.togglePin(
                                meeting.id,
                                !meeting.isPinned,
                              );
                              _loadMeetings();
                            },
                            child: Icon(
                              meeting.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meeting.purpose,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                meeting.time ?? 'TBD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              switch (meeting.status) {
                                MeetingStatus.accepted => 'Upcoming',
                                MeetingStatus.rejected => 'Rejected',
                                MeetingStatus.pending => 'Pending',
                                MeetingStatus.completed => 'Completed',
                              },
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
