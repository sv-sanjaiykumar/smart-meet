import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../services/storage_service.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Requests Monitoring',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
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
    
    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredMeetings.length,
        itemBuilder: (context, index) {
          final meeting = filteredMeetings[index];
          return _buildRequestCard(meeting);
        },
      ),
    );
  }

  Widget _buildRequestCard(Meeting meeting) {
    Color barColor = Colors.blue;
    if (meeting.status == MeetingStatus.accepted) barColor = Colors.green;
    if (meeting.status == MeetingStatus.rejected) barColor = Colors.red;
    if (meeting.status == MeetingStatus.pending) barColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: meeting.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.facultyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(meeting.facultyDept, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (meeting.isPinned)
                  Icon(Icons.push_pin, size: 18, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.purpose, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        meeting.status == MeetingStatus.rejected 
                            ? (meeting.denialReason ?? 'No reason provided') 
                            : 'Requested on ${meeting.requestedAt}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
            if (meeting.time != null && meeting.status != MeetingStatus.rejected) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(meeting.time!, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 20),
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(meeting.location ?? 'TBD', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
