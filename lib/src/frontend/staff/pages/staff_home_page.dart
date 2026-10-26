import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/auth_service.dart';
import '../../../backend/meeting_service.dart';
import '../../student/models/meeting.dart';
import '../theme/staff_theme.dart';
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
  final AuthService _authService = AuthService();
  StreamSubscription<List<Meeting>>? _meetingSubscription;

  List<Meeting> _meetings = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  String _requestFilter = 'Pending';

  @override
  void initState() {
    super.initState();
    _loadMeetings();
    _subscribeToMeetings();
  }

  @override
  void dispose() {
    _meetingSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMeetings() async {
    final user = await _authService.getCurrentUser();
    final uid = user?.uid;
    _meetingSubscription?.cancel();
    _meetingSubscription = _meetingService
        .streamMeetingsForStaff(user?.displayName, uid)
        .listen((meetings) {
      if (mounted) {
        setState(() {
          _meetings = meetings;
          _isLoading = false;
        });
      }
    });
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
      await _showScheduleMeetingSheet(meeting, isAccepting: true);
      return;
    } else if (status == MeetingStatus.rejected) {
      await _meetingService.rejectMeeting(meeting.id);
    } else {
      await _meetingService.completeMeeting(meeting.id);
    }
    await _loadMeetings();
  }

  Future<void> _showScheduleMeetingSheet(
    Meeting meeting, {
    bool isAccepting = false,
  }) async {
    final timeController = TextEditingController(text: meeting.time ?? '');
    final locationController =
        TextEditingController(text: meeting.location ?? '');

    const quickVenues = [
      'TF-03',
      'Faculty Cabin',
      'CSE Staff Room',
      'Lab 1',
      'HOD Cabin',
      'Seminar Hall',
    ];

    const quickTimes = [
      '10:00 AM',
      '11:30 AM',
      '12:45 PM',
      '02:00 PM',
      '03:30 PM',
      '04:30 PM',
    ];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: StaffColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: StaffColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAccepting
                                    ? 'Accept & Schedule Meeting'
                                    : 'Set Meeting Time & Place',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: StaffColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'With ${meeting.studentName ?? 'Student'} • ${meeting.purpose}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: StaffColors.mutedInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Meeting Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: StaffColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: timeController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 11:30 AM',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.access_time,
                              color: StaffColors.primary,
                            ),
                            onPressed: () async {
                              final now = TimeOfDay.now();
                              final picked = await showTimePicker(
                                context: bottomSheetContext,
                                initialTime: now,
                              );
                              if (picked != null && bottomSheetContext.mounted) {
                                final formatted =
                                    picked.format(bottomSheetContext);
                                setModalState(() {
                                  timeController.text = formatted;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickTimes.map((t) {
                          final isSelected = timeController.text == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(t),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? Colors.white : StaffColors.ink,
                              ),
                              backgroundColor: isSelected
                                  ? StaffColors.primary
                                  : Colors.grey[100],
                              side: BorderSide(
                                color: isSelected
                                    ? StaffColors.primary
                                    : Colors.grey[300]!,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  timeController.text = t;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Meeting Place / Venue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: StaffColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. TF-03 or Faculty Cabin',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on_outlined,
                            color: StaffColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickVenues.map((v) {
                          final isSelected = locationController.text == v;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(v),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? Colors.white : StaffColors.ink,
                              ),
                              backgroundColor: isSelected
                                  ? StaffColors.primary
                                  : Colors.grey[100],
                              side: BorderSide(
                                color: isSelected
                                    ? StaffColors.primary
                                    : Colors.grey[300]!,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  locationController.text = v;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(bottomSheetContext, false),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: StaffColors.mutedInk),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(bottomSheetContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StaffColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isAccepting
                                  ? 'Confirm & Accept'
                                  : 'Save Details',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      final finalTime = timeController.text.trim();
      final finalLocation = locationController.text.trim();

      final shouldAccept =
          isAccepting || meeting.status == MeetingStatus.pending;
      if (shouldAccept) {
        await _meetingService.acceptMeeting(
          meeting.id,
          time: finalTime.isEmpty ? null : finalTime,
          location: finalLocation.isEmpty ? null : finalLocation,
        );
      } else {
        await _meetingService.editMeetingDetails(
          meeting.id,
          time: finalTime.isEmpty ? null : finalTime,
          location: finalLocation.isEmpty ? null : finalLocation,
        );
      }

      await _loadMeetings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldAccept
                  ? 'Meeting accepted and scheduled!'
                  : 'Meeting time and place updated!',
            ),
            backgroundColor: StaffColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _currentDateLabel() {
    final now = DateTime.now();
    final day = now.day;
    final suffix = switch (day % 10) {
      1 when day % 100 != 11 => 'st',
      2 when day % 100 != 12 => 'nd',
      3 when day % 100 != 13 => 'rd',
      _ => 'th',
    };
    return '$day$suffix ${DateFormat.MMMM().format(now)}';
  }

  Widget _getBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selectedTab) {
      case 0:
        return _buildHome();
      case 1:
        return StaffRequestsPage(
          meetings: _meetings,
          onRefresh: _loadMeetings,
          onStatusChanged: _updateMeetingStatus,
          onEditMeeting: (meeting) => _showScheduleMeetingSheet(meeting),
        );
      case 2:
        return StaffHistoryPage(meetings: _meetings, onRefresh: _loadMeetings);
      case 3:
        return StaffNotificationsPage(
          meetings: _meetings,
          onRefresh: _loadMeetings,
          onBack: () => setState(() => _selectedTab = 0),
          onEditReminder: (meeting) => _showScheduleMeetingSheet(meeting),
        );
      case 4:
        return StaffProfilePage(
          onBack: () => setState(() => _selectedTab = 0),
        );
      default:
        return _buildHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffColors.background,
      body: SafeArea(bottom: false, child: _getBody()),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  // ── Floating glassmorphic bottom nav (mirrors student design) ──────────
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
              _buildNavItem(
                1,
                Icons.calendar_month_outlined,
                Icons.calendar_month,
              ),
              _buildNavItem(2, Icons.history_outlined, Icons.history),
              _buildNavItem(
                3,
                Icons.notifications_none,
                Icons.notifications,
              ),
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
      onTap: () => setState(() => _selectedTab = index),
      child: Icon(
        isSelected ? selectedIcon : icon,
        color: StaffColors.ink,
        size: 28,
      ),
    );
  }

  // ── Home tab ───────────────────────────────────────────────────────────
  Widget _buildHome() {
    final upcomingMeetings = _meetings
        .where((meeting) => meeting.status == MeetingStatus.accepted)
        .toList();
    final allPending = _meetings
        .where((meeting) => meeting.status == MeetingStatus.pending)
        .toList();

    DateTime? parseDate(Meeting m) {
      if (m.createdAt != null) return m.createdAt;
      final ts = RegExp(r'req_(\d+)').firstMatch(m.id)?.group(1);
      if (ts != null) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      }
      try {
        return DateFormat('d MMM, h:mm a').parse(m.requestedAt);
      } catch (_) {
        return null;
      }
    }

    bool isNew(Meeting m) {
      final date = parseDate(m);
      if (date == null) return true;
      final diff = DateTime.now().difference(date);
      return !diff.isNegative && diff.inHours < 48;
    }

    bool isUrgent(Meeting m) {
      final p = m.purpose.toLowerCase();
      const urgentWords = [
        'urgent',
        'emergency',
        'asap',
        'immediate',
        'today',
        'sign',
        'form',
        'exam',
        'approval',
        'deadline',
      ];
      if (urgentWords.any((w) => p.contains(w))) return true;
      if (m.meetingDate != null) {
        final now = DateTime.now();
        final diff = m.meetingDate!.difference(
          DateTime(now.year, now.month, now.day),
        );
        if (diff.inDays <= 0) return true;
      }
      return false;
    }

    final newRequests = allPending.where(isNew).toList();
    final urgentRequests = allPending.where(isUrgent).toList();

    final List<Meeting> displayedRequests;
    final String emptyMessage;
    if (_requestFilter == 'New') {
      displayedRequests = newRequests;
      emptyMessage = 'No new requests in the last 48 hours';
    } else if (_requestFilter == 'Urgent') {
      displayedRequests = urgentRequests;
      emptyMessage = 'No urgent requests';
    } else {
      displayedRequests = allPending;
      emptyMessage = 'No pending requests';
    }

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
            _buildWelcomeCard(),
            const SizedBox(height: 28),
            const Text(
              "Today's meetings",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: StaffColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            if (upcomingMeetings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'No meetings yet. New student requests will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: StaffColors.mutedInk),
                ),
              )
            else
              SizedBox(
                height: 156,
                child: PageView.builder(
                  itemCount: upcomingMeetings.length,
                  padEnds: false,
                  controller: PageController(viewportFraction: 0.92),
                  itemBuilder: (context, index) =>
                      _buildMeetingCard(upcomingMeetings[index]),
                ),
              ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Requests',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: StaffColors.ink,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  child: const Text(
                    'view all',
                    style: TextStyle(
                      fontSize: 15,
                      color: StaffColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    'Pending',
                    isSelected: _requestFilter == 'Pending',
                    count: allPending.length,
                    onTap: () => setState(() => _requestFilter = 'Pending'),
                  ),
                  const SizedBox(width: 10),
                  _filterChip(
                    'New',
                    isSelected: _requestFilter == 'New',
                    count: newRequests.length,
                    onTap: () => setState(() => _requestFilter = 'New'),
                  ),
                  const SizedBox(width: 10),
                  _filterChip(
                    'Urgent',
                    isSelected: _requestFilter == 'Urgent',
                    count: urgentRequests.length,
                    onTap: () => setState(() => _requestFilter = 'Urgent'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (displayedRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _requestFilter == 'Urgent'
                          ? Icons.offline_bolt_outlined
                          : _requestFilter == 'New'
                              ? Icons.mark_email_read_outlined
                              : Icons.inbox_outlined,
                      size: 32,
                      color: StaffColors.mutedInk.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: StaffColors.mutedInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedRequests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _buildRequestTile(displayedRequests[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.menu, size: 28, color: StaffColors.ink),
        Text(
          _currentDateLabel(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: StaffColors.ink,
          ),
        ),
        const Icon(Icons.settings_outlined, size: 26, color: StaffColors.ink),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final meetingCount = _meetings
        .where((m) => m.status == MeetingStatus.accepted)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                colors: [StaffColors.primary, Color(0xFFBFE0FC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: StaffColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  color: StaffColors.ink,
                  height: 1.25,
                  fontFamily: 'Poppins',
                ),
                children: [
                  const TextSpan(
                    text: 'Hello, Faculty\n',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text:
                        'Ready for $meetingCount ${meetingCount == 1 ? 'meeting' : 'meetings'} today!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    final hasLocation =
        meeting.location != null && meeting.location!.trim().isNotEmpty;
    final hasTime = meeting.time != null && meeting.time!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _showScheduleMeetingSheet(meeting),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFB5C8FF), Color(0xFFE9EDFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB5C8FF).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meeting.studentName ?? 'Student',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: StaffColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Material(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showScheduleMeetingSheet(meeting),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Tooltip(
                        message: 'Edit time & place',
                        child: Icon(
                          Icons.edit_note,
                          size: 22,
                          color: StaffColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${meeting.facultyDept.toLowerCase()} • ${meeting.purpose}',
              style: TextStyle(
                fontSize: 15,
                color: StaffColors.ink.withValues(alpha: 0.7),
                height: 1.35,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _showScheduleMeetingSheet(meeting),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasLocation
                          ? Colors.white.withValues(alpha: 0.55)
                          : StaffColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: hasLocation
                              ? StaffColors.mutedInk
                              : StaffColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasLocation ? meeting.location! : 'Set place',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasLocation
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: hasLocation
                                ? StaffColors.mutedInk
                                : StaffColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showScheduleMeetingSheet(meeting),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasTime
                          ? Colors.white.withValues(alpha: 0.55)
                          : StaffColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 15,
                          color: hasTime
                              ? StaffColors.mutedInk
                              : StaffColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasTime ? meeting.time! : 'Set time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasTime
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: hasTime
                                ? StaffColors.mutedInk
                                : StaffColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(Meeting meeting) {
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
            backgroundColor: StaffColors.cardBlue,
            child: const Icon(
              Icons.person,
              color: StaffColors.ink,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      meeting.studentName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: StaffColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: StaffColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meeting.facultyDept
                            .replaceAll('Dept of ', '')
                            .toLowerCase(),
                        style: const TextStyle(
                          color: StaffColors.mutedInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Reject request',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: StaffColors.mutedInk,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('Reject Request?'),
                            content: Text(
                              'Are you sure you want to reject the meeting request from ${meeting.studentName ?? "student"}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _updateMeetingStatus(meeting, MeetingStatus.rejected);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  meeting.purpose,
                  style: const TextStyle(
                    fontSize: 15,
                    color: StaffColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meeting.id.length > 8
                          ? meeting.id.substring(0, 8).toUpperCase()
                          : meeting.id.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: StaffColors.mutedInk,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showScheduleMeetingSheet(
                        meeting,
                        isAccepting: true,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: StaffColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: StaffColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (meeting.time != null && meeting.location != null)
                                  ? '${meeting.time!} • ${meeting.location!}'
                                  : (meeting.time ?? 'Set time & venue'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: StaffColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _updateMeetingStatus(
                      meeting,
                      MeetingStatus.accepted,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text(
                      'accept & schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: StaffColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label, {
    required bool isSelected,
    VoidCallback? onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? StaffColors.primary.withValues(alpha: 0.18)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? StaffColors.primary.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count != null && count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? StaffColors.primary : StaffColors.ink,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) const SizedBox(width: 6),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: StaffColors.primary),
          ],
        ),
      ),
    );
  }
}
