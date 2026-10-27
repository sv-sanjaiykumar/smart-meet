import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../student/models/meeting.dart';
import '../theme/staff_theme.dart';

class StaffHistoryPage extends StatefulWidget {
  const StaffHistoryPage({
    super.key,
    required this.meetings,
    required this.onRefresh,
    this.onStatusChanged,
    this.onEditMeeting,
  });

  final List<Meeting> meetings;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Meeting meeting, MeetingStatus status)? onStatusChanged;
  final Future<void> Function(Meeting meeting)? onEditMeeting;

  @override
  State<StaffHistoryPage> createState() => _StaffHistoryPageState();
}

class _StaffHistoryPageState extends State<StaffHistoryPage> {
  static const _ink = StaffColors.ink;
  static const _muted = StaffColors.mutedInk;
  static const _accent = StaffColors.primary;

  late DateTime _selectedDate;
  bool _newestFirst = true;
  final Set<String> _expandedIds = {};
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  /// Extracts the effective date for a meeting.
  /// Prioritizes meetingDate, then createdAt, then timestamp in id, then requestedAt.
  DateTime? _getMeetingDate(Meeting meeting) {
    if (meeting.meetingDate != null) return meeting.meetingDate;
    if (meeting.createdAt != null) return meeting.createdAt;

    final timestamp = RegExp(r'req_(\d+)').firstMatch(meeting.id)?.group(1);
    if (timestamp != null) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {}
    }

    if (meeting.requestedAt.isNotEmpty) {
      final iso = DateTime.tryParse(meeting.requestedAt);
      if (iso != null) return iso;

      for (final format in [
        'd MMM yyyy, h:mm a',
        'd MMMM yyyy, h:mm a',
        'd MMM, h:mm a',
        'dd MMM, h:mm a',
        'd MMMM, h:mm a',
        'MMMM d, yyyy',
        'd MMM',
      ]) {
        try {
          final parsed = DateFormat(format).parse(meeting.requestedAt);
          if (parsed.year <= 1970) {
            final now = DateTime.now();
            return DateTime(
              now.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
            );
          }
          return parsed;
        } catch (_) {}
      }
    }
    return null;
  }

  /// Checks whether a meeting belongs to a specific calendar day.
  bool _isForDay(Meeting meeting, DateTime targetDay) {
    final date = _getMeetingDate(meeting);
    if (date == null) return false;

    if (date.year == targetDay.year &&
        date.month == targetDay.month &&
        date.day == targetDay.day) {
      return true;
    }

    // Fallback if year was not saved (defaulted to 1970 or current year)
    if ((date.year == 1970 || date.year == DateTime.now().year) &&
        date.month == targetDay.month &&
        date.day == targetDay.day) {
      return true;
    }

    return false;
  }

  /// Returns sorted meetings for the selected day, optionally filtered by status.
  List<Meeting> _history([MeetingStatus? status]) {
    final entries = widget.meetings.where((meeting) {
      if (status != null && meeting.status != status) return false;
      return _isForDay(meeting, _selectedDate);
    }).toList();

    entries.sort((a, b) {
      final first = _getMeetingDate(a) ?? DateTime(1970);
      final second = _getMeetingDate(b) ?? DateTime(1970);
      return _newestFirst ? second.compareTo(first) : first.compareTo(second);
    });

    return entries;
  }

  /// Counts total meetings on a given day.
  int _countForDay(DateTime day) {
    return widget.meetings.where((m) => _isForDay(m, day)).length;
  }

  void _changeMonth(int difference) {
    final month = DateTime(
      _selectedDate.year,
      _selectedDate.month + difference,
      1,
    );
    final finalDay = DateTime(month.year, month.month + 1, 0).day;
    setState(() {
      _selectedDate = DateTime(
        month.year,
        month.month,
        _selectedDate.day.clamp(1, finalDay),
      );
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  String _dateHeaderLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) {
      return 'Today, ${DateFormat('MMM d').format(_selectedDate)}';
    } else if (difference == 1) {
      return 'Tomorrow, ${DateFormat('MMM d').format(_selectedDate)}';
    } else if (difference == -1) {
      return 'Yesterday, ${DateFormat('MMM d').format(_selectedDate)}';
    }
    return DateFormat('EEE, MMM d').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final allDayMeetings = _history();
    final scheduled = _history(MeetingStatus.accepted);
    final pending = _history(MeetingStatus.pending);
    final completed = _history(MeetingStatus.completed);
    final cancelled = _history(MeetingStatus.rejected);

    final List<Meeting> displayedMeetings;
    if (_statusFilter == 'Scheduled') {
      displayedMeetings = scheduled;
    } else if (_statusFilter == 'Pending') {
      displayedMeetings = pending;
    } else if (_statusFilter == 'Completed') {
      displayedMeetings = completed;
    } else if (_statusFilter == 'Cancelled') {
      displayedMeetings = cancelled;
    } else {
      displayedMeetings = allDayMeetings;
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'History',
          style: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 18),

        // ── Month selector with calendar picker ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: _muted),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickCustomDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(color: _ink),
                          children: [
                            TextSpan(
                              text: DateFormat('MMMM').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' ${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: _muted),
              ),
            ],
          ),
        ),

        // ── 5-Day selector strip ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Row(
            children: List.generate(5, (index) {
              final date = _selectedDate.add(Duration(days: index - 2));
              final selected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final meetingCount = _countForDay(date);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDay(date, selected, meetingCount),
                ),
              );
            }),
          ),
        ),

        // ── Status Filter Chips ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', allDayMeetings.length),
                const SizedBox(width: 8),
                _filterChip('Scheduled', scheduled.length),
                const SizedBox(width: 8),
                _filterChip('Pending', pending.length),
                const SizedBox(width: 8),
                _filterChip('Completed', completed.length),
                const SizedBox(width: 8),
                _filterChip('Cancelled', cancelled.length),
              ],
            ),
          ),
        ),

        // ── Date subtitle & Sort popup ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _dateHeaderLabel(),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: allDayMeetings.isNotEmpty
                          ? _accent.withValues(alpha: 0.12)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${allDayMeetings.length} ${allDayMeetings.length == 1 ? 'meeting' : 'meetings'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: allDayMeetings.isNotEmpty ? _accent : _muted,
                      ),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<bool>(
                tooltip: 'Sort history',
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
                    SizedBox(width: 6),
                    Icon(Icons.tune, size: 18, color: _muted),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Meeting Cards List ───────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              children: [
                if (_statusFilter == 'All') ...[
                  if (scheduled.isNotEmpty) ...[
                    _sectionHeader('Scheduled Meetings', scheduled.length, const Color(0xFF17C964)),
                    const SizedBox(height: 10),
                    ...scheduled.map(_historyCard),
                  ],
                  if (pending.isNotEmpty) ...[
                    _sectionHeader('Pending Requests', pending.length, const Color(0xFFFFA726)),
                    const SizedBox(height: 10),
                    ...pending.map(_historyCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    _sectionHeader('Completed Meetings', completed.length, _accent),
                    const SizedBox(height: 10),
                    ...completed.map(_historyCard),
                  ],
                  if (cancelled.isNotEmpty) ...[
                    _sectionHeader('Cancelled Meetings', cancelled.length, const Color(0xFFFF625A)),
                    const SizedBox(height: 10),
                    ...cancelled.map(_historyCard),
                  ],
                ] else ...[
                  if (displayedMeetings.isNotEmpty) ...[
                    _sectionHeader('$_statusFilter Meetings', displayedMeetings.length, _accent),
                    const SizedBox(height: 10),
                    ...displayedMeetings.map(_historyCard),
                  ],
                ],
                if (displayedMeetings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 76),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 42, color: Color(0xFFB8B8B8)),
                        SizedBox(height: 12),
                        Text(
                          'No meetings on this day',
                          style: TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _accent : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _ink,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDay(DateTime date, bool selected, int meetingCount) {
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('EEEE, d MMMM yyyy').format(date),
      child: GestureDetector(
        onTap: () => setState(
          () => _selectedDate = DateTime(date.year, date.month, date.day),
        ),
        child: Container(
          height: selected ? 86 : 74,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: selected ? Border.all(color: _accent.withValues(alpha: 0.4), width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.09 : 0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(date),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: selected ? _ink : _muted,
                ),
              ),
              Text(
                DateFormat('EEE').format(date),
                style: TextStyle(fontSize: 12, color: selected ? _ink : _muted),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (meetingCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: selected ? _accent : const Color(0xFFFFA726),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    width: selected ? 20 : 6,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: indicatorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Meeting meeting) {
    final expanded = _expandedIds.contains(meeting.id);
    final isCancelled = meeting.status == MeetingStatus.rejected;
    final isCompleted = meeting.status == MeetingStatus.completed;
    final isPending = meeting.status == MeetingStatus.pending;
    final isScheduled = meeting.status == MeetingStatus.accepted;

    final name = meeting.studentName?.trim().isNotEmpty == true
        ? meeting.studentName!.trim()
        : 'Student';
    final initials = name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join()
        .toUpperCase();
    final department = meeting.facultyDept
        .replaceAll('Dept of ', '')
        .trim()
        .toUpperCase();
    final plannedDate = _getMeetingDate(meeting);

    final (statusLabel, statusColor) = switch (meeting.status) {
      MeetingStatus.accepted => ('Scheduled', const Color(0xFF17C964)),
      MeetingStatus.pending => ('Pending', const Color(0xFFFFA726)),
      MeetingStatus.completed => ('Completed', _accent),
      MeetingStatus.rejected => ('Cancelled', const Color(0xFFFF625A)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(
            () => expanded
                ? _expandedIds.remove(meeting.id)
                : _expandedIds.add(meeting.id),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top user info and badges
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Text(
                        initials.isNotEmpty ? initials : 'S',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          Text(
                            meeting.id.replaceFirst('req_', '').toUpperCase(),
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _statusBadge(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 12),

                // Purpose row with bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        meeting.purpose,
                        maxLines: expanded ? 6 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 21,
                      color: _muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time, venue, and status specifics
                if (isCancelled)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _datePill('Planned on', plannedDate),
                      _datePill('Cancelled on', plannedDate),
                    ],
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (meeting.time?.isNotEmpty == true)
                        _detail(Icons.access_time, meeting.time!)
                      else if (isScheduled)
                        _detail(Icons.access_time, 'Time to be decided'),
                      if (meeting.location?.isNotEmpty == true)
                        _detail(Icons.location_on_outlined, meeting.location!)
                      else if (isScheduled)
                        _detail(Icons.location_on_outlined, 'Venue to be decided'),
                      if (isCompleted)
                        _datePill('Completed on', plannedDate),
                    ],
                  ),

                if (expanded && meeting.denialReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  _detail(Icons.info_outline, meeting.denialReason!),
                ],

                // Action buttons if callbacks provided
                if (isScheduled && (widget.onEditMeeting != null || widget.onStatusChanged != null)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.onEditMeeting != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onEditMeeting!(meeting),
                            icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                            label: const Text('Time & Venue', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: BorderSide(color: _accent.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      if (widget.onEditMeeting != null && widget.onStatusChanged != null)
                        const SizedBox(width: 8),
                      if (widget.onStatusChanged != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onStatusChanged!(
                              meeting,
                              MeetingStatus.completed,
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 15),
                            label: const Text('Complete', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17C964),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                if (isPending && widget.onStatusChanged != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onStatusChanged!(
                            meeting,
                            MeetingStatus.accepted,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text(
                            'Accept & Schedule',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => widget.onStatusChanged!(
                            meeting,
                            MeetingStatus.rejected,
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF625A),
                            side: BorderSide(color: const Color(0xFFFF625A).withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePill(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: label == 'Cancelled on'
              ? const Color(0xFFEBA6F2)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: ${date == null ? 'Date unavailable' : DateFormat('MMM dd, yyyy').format(date)}',
        style: const TextStyle(fontSize: 11, color: _muted),
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: _muted),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontSize: 12, color: _muted)),
    ],
  );
}
