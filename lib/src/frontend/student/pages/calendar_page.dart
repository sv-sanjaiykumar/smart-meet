import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../services/storage_service.dart';
import '../theme/student_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final meetings = await _storageService.getMeetings();
    setState(() {
      _meetings = meetings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        backgroundColor: StudentColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Request Monitoring',
          style: TextStyle(color: StudentColors.ink, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: StudentColors.ink,
          unselectedLabelColor: StudentColors.mutedInk,
          indicatorColor: StudentColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Accepted'),
            Tab(text: 'Denied'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(MeetingStatus.completed),
              _buildRequestList(MeetingStatus.accepted),
              _buildRequestList(MeetingStatus.rejected),
              _buildRequestList(MeetingStatus.pending),
            ],
          ),
    );
  }

  Widget _buildRequestList(MeetingStatus status) {
    final filteredMeetings = _meetings.where((m) => m.status == status).toList();
    
    if (filteredMeetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: StudentColors.mutedInk.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No ${status.name} requests found', style: const TextStyle(color: StudentColors.mutedInk)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for nav bar
        itemCount: filteredMeetings.length,
        itemBuilder: (context, index) {
          final meeting = filteredMeetings[index];
          return _buildRequestCard(meeting);
        },
      ),
    );
  }

  Widget _buildRequestCard(Meeting meeting) {
    Color barColor = StudentColors.primary;
    if (meeting.status == MeetingStatus.accepted) barColor = Colors.green;
    if (meeting.status == MeetingStatus.rejected) barColor = Colors.red;
    if (meeting.status == MeetingStatus.pending) barColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: StudentColors.softBlue,
                  child: const Icon(Icons.person, color: StudentColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.facultyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: StudentColors.ink)),
                      Text(meeting.facultyDept, style: const TextStyle(color: StudentColors.mutedInk, fontSize: 13)),
                    ],
                  ),
                ),
                if (meeting.isPinned)
                  Icon(Icons.push_pin, size: 20, color: StudentColors.mutedInk.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 45,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.purpose, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: StudentColors.ink)),
                      const SizedBox(height: 4),
                      Text(
                        meeting.status == MeetingStatus.rejected 
                            ? (meeting.denialReason ?? 'No reason provided') 
                            : 'Requested on ${meeting.requestedAt}',
                        style: TextStyle(color: StudentColors.mutedInk, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: StudentColors.mutedInk),
              ],
            ),
            if (meeting.time != null || meeting.location != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (meeting.time != null) ...[
                    const Icon(Icons.access_time, size: 18, color: StudentColors.mutedInk),
                    const SizedBox(width: 8),
                    Text(meeting.time!, style: const TextStyle(color: StudentColors.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 24),
                  ],
                  if (meeting.location != null) ...[
                    const Icon(Icons.location_on_outlined, size: 18, color: StudentColors.mutedInk),
                    const SizedBox(width: 8),
                    Text(meeting.location!, style: const TextStyle(color: StudentColors.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
