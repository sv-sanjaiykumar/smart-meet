import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../student/models/meeting.dart';
import '../theme/staff_theme.dart';

class StaffNotificationsPage extends StatefulWidget {
  const StaffNotificationsPage({
    super.key,
    required this.meetings,
    required this.onRefresh,
    required this.onBack,
    required this.onEditReminder,
  });

  final List<Meeting> meetings;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final Future<void> Function(Meeting meeting) onEditReminder;

  @override
  State<StaffNotificationsPage> createState() => _StaffNotificationsPageState();
}

class _StaffNotificationsPageState extends State<StaffNotificationsPage>
    with SingleTickerProviderStateMixin {
  static const _ink = StaffColors.ink;
  static const _muted = StaffColors.mutedInk;
  static const _blue = StaffColors.primary;

  late final TabController _tabController;
  bool _newestFirst = true;
  final Set<String> _expandedIds = {};
  bool _reminderSnoozed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime? _dateFor(Meeting meeting) {
    try {
      return DateFormat('d MMM, h:mm a').parse(meeting.requestedAt);
    } on FormatException {
      final timestamp = RegExp(r'req_(\d+)').firstMatch(meeting.id)?.group(1);
      return timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    }
  }

  List<Meeting> _sortedMeetings(MeetingStatus status) {
    final meetings = widget.meetings
        .where((meeting) => meeting.status == status)
        .toList();
    meetings.sort((first, second) {
      final firstDate = _dateFor(first) ?? DateTime(1970);
      final secondDate = _dateFor(second) ?? DateTime(1970);
      return _newestFirst
          ? secondDate.compareTo(firstDate)
          : firstDate.compareTo(secondDate);
    });
    return meetings;
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _sortedMeetings(MeetingStatus.accepted);
    final cancelled = _sortedMeetings(MeetingStatus.rejected);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to home',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: _ink),
              ),
              const Text(
                'Notification',
                style: TextStyle(fontSize: 21, color: _ink),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: _ink,
          unselectedLabelColor: _ink,
          indicatorColor: _ink,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Reminders'),
            Tab(text: 'System'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Due today',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              PopupMenuButton<bool>(
                tooltip: 'Sort notifications',
                onSelected: (newestFirst) =>
                    setState(() => _newestFirst = newestFirst),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: true, child: Text('Newest first')),
                  PopupMenuItem(value: false, child: Text('Oldest first')),
                ],
                child: const Row(
                  children: [
                    Text(
                      'Sort By',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.tune, size: 18, color: _muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(accepted, cancelled, includeSystem: true),
              _buildList(accepted, cancelled),
              _buildList(
                const [],
                const [],
                includeSystem: true,
                systemOnly: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<Meeting> accepted,
    List<Meeting> cancelled, {
    bool includeSystem = false,
    bool systemOnly = false,
  }) {
    final notifications = <Widget>[];
    if (!systemOnly) {
      final meetings = [...accepted, ...cancelled];
      meetings.sort((first, second) {
        final firstDate = _dateFor(first) ?? DateTime(1970);
        final secondDate = _dateFor(second) ?? DateTime(1970);
        return _newestFirst
            ? secondDate.compareTo(firstDate)
            : firstDate.compareTo(secondDate);
      });
      notifications.addAll(
        meetings.map(
          (meeting) => meeting.status == MeetingStatus.accepted
              ? _buildReminderCard(meeting)
              : _buildCancelledCard(meeting),
        ),
      );
    }
    if (includeSystem) notifications.add(_buildSystemCard());

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 90),
          children: const [
            Icon(Icons.notifications_none, size: 42, color: Color(0xFFBBBBBB)),
            SizedBox(height: 12),
            Center(
              child: Text('No reminders yet', style: TextStyle(color: _muted)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 104),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => notifications[index],
      ),
    );
  }

  Widget _buildReminderCard(Meeting meeting) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(const Color(0xFFB8F3C8)),
      child: Row(
        children: [
          _avatar(meeting),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: _ink, fontSize: 13),
                    children: [
                      const TextSpan(
                        text: 'Next up: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            '${meeting.purpose} with ${meeting.studentName ?? 'Student'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    if (meeting.time?.isNotEmpty == true)
                      _detailChip(Icons.access_time, meeting.time!),
                    if (meeting.location?.isNotEmpty == true)
                      _detailChip(
                        Icons.location_on_outlined,
                        meeting.location!,
                      ),
                    _statusChip('Updated', const Color(0xFF1BA84B)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit reminder',
            visualDensity: VisualDensity.compact,
            onPressed: () => widget.onEditReminder(meeting),
            icon: const Icon(Icons.edit_outlined, size: 18, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(Meeting meeting) {
    final expanded = _expandedIds.contains(meeting.id);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => setState(
        () => expanded
            ? _expandedIds.remove(meeting.id)
            : _expandedIds.add(meeting.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(const Color(0xFFFFC4C4)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(meeting),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meeting.studentName ?? 'Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      _statusChip('Cancelled', const Color(0xFFE53935)),
                    ],
                  ),
                  Text(
                    '${meeting.id.replaceFirst('req_', '').toUpperCase()} - ${meeting.facultyDept.replaceAll('Dept of ', '')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Cancelled: ${meeting.denialReason ?? 'Meeting request declined'}',
                    maxLines: expanded ? 4 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _ink),
                  ),
                  if (expanded && meeting.time?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _detailChip(Icons.access_time, meeting.time!),
                  ],
                ],
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 22,
              color: _ink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(const Color(0xFFC6DCFF)),
      child: Row(
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: Icon(Icons.hub_outlined, color: _blue, size: 42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: _ink, height: 1.35),
                    children: [
                      TextSpan(
                        text: 'System Update: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: 'Your Smart Meet notifications are up to date.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _reminderSnoozed = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFFB9D2FF)),
                      ),
                      child: Text(
                        _reminderSnoozed ? 'Reminder set' : 'Remind Later',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text('Smart Meet is up to date'),
                            ),
                          ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: _blue),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 12),
                      label: const Text(
                        'Update now',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Meeting meeting) {
    final name = meeting.studentName?.trim().isNotEmpty == true
        ? meeting.studentName!.trim()
        : 'Student';
    final initials = name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE8EDF5),
      child: Text(
        initials,
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color borderColor) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: borderColor.withValues(alpha: 0.7)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _detailChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD8D8D8)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _ink)),
      ],
    ),
  );

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD8D8D8)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: _ink)),
      ],
    ),
  );
}
