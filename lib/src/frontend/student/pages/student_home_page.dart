import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/meeting.dart';
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
  final List<Meeting> meetings = dummyMeetings;

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
        return const ProfilePage();
      default:
        return _buildHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _getBody(),
      ),
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
              _buildNavItem(1, Icons.calendar_month_outlined, Icons.calendar_month),
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

  void _showRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RequestMeetingSheet(),
    );
  }

  String _destinationTitle(int index) {
    const titles = ['Home', 'Your calendar', 'Create a meeting', 'Notifications', 'Your profile'];
    return titles[index];
  }

  Widget _buildHome(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100), // Added bottom padding for nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 28),
          ...meetings.map((meeting) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildMeetingCard(meeting),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestsPage())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('July 30th, 2025', style: TextStyle(color: StudentColors.mutedInk, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('Hey, Thoufik!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Requests status..', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: StudentColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.wb_sunny_outlined, color: StudentColors.primary, size: 24),
        ),
      ],
    );
  }

  Widget _buildStats() {
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
      child: Row(
        children: [
          _buildStatItem('3', 'Accepted', true),
          _buildStatItem('2', 'Rejected', false),
          _buildStatItem('1', 'Pending', false),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? StudentColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive ? [
            BoxShadow(
              color: StudentColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : StudentColors.ink,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.white : StudentColors.mutedInk,
              ),
            ),
          ],
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
          // Illustration Placeholder (More detailed)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.school, size: 80, color: StudentColors.primary.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 24, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 40),
                    Icon(Icons.lightbulb, size: 24, color: Colors.white.withValues(alpha: 0.6)),
                  ],
                )
              ],
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
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_on, color: StudentColors.primary, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    meeting.location ?? 'TBD',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                          Icon(
                            meeting.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: Colors.white,
                            size: 20,
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
                              const Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                meeting.time ?? 'TBD',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Upcoming',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}
