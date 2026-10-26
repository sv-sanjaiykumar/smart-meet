import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../student/models/meeting.dart';
import '../theme/staff_theme.dart';

class StaffHistoryPage extends StatefulWidget {
  const StaffHistoryPage({
    super.key,
    required this.meetings,
    required this.onRefresh,
  });

  final List<Meeting> meetings;
  final Future<void> Function() onRefresh;

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

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  DateTime? _requestedDate(Meeting meeting) {
    try {
      return DateFormat('d MMM, h:mm a').parse(meeting.requestedAt);
    } on FormatException {
      final timestamp = RegExp(r'req_(\d+)').firstMatch(meeting.id)?.group(1);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      }
      return null;
    }
  }

  List<Meeting> _history(MeetingStatus status) {
    final entries = widget.meetings.where((meeting) {
      if (meeting.status != status) return false;
      final date = _requestedDate(meeting);
      return date != null &&
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
    }).toList();
    entries.sort((a, b) {
      final first = _requestedDate(a) ?? DateTime(1970);
      final second = _requestedDate(b) ?? DateTime(1970);
      return _newestFirst ? second.compareTo(first) : first.compareTo(second);
    });
    return entries;
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

  @override
  Widget build(BuildContext context) {
    final cancelled = _history(MeetingStatus.rejected);
    final completed = _history(MeetingStatus.completed);

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
        const SizedBox(height: 22),
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
                child: Text.rich(
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
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: _muted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
          child: Row(
            children: List.generate(5, (index) {
              final date = _selectedDate.add(Duration(days: index - 2));
              final selected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDay(date, selected),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE, MMM d').format(_selectedDate),
                style: const TextStyle(color: _muted, fontSize: 13),
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
                    SizedBox(width: 8),
                    Icon(Icons.tune, size: 18, color: _muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              children: [
                if (cancelled.isNotEmpty) ...[
                  _sectionTitle('Cancelled Meetings'),
                  const SizedBox(height: 10),
                  ...cancelled.map(
                    (meeting) => _historyCard(meeting, cancelled: true),
                  ),
                ],
                if (completed.isNotEmpty) ...[
                  _sectionTitle('Completed Meetings'),
                  const SizedBox(height: 10),
                  ...completed.map(
                    (meeting) => _historyCard(meeting, cancelled: false),
                  ),
                ],
                if (cancelled.isEmpty && completed.isEmpty)
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

  Widget _buildDay(DateTime date, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('EEEE, d MMMM yyyy').format(date),
      child: GestureDetector(
        onTap: () => setState(
          () => _selectedDate = DateTime(date.year, date.month, date.day),
        ),
        child: Container(
          height: selected ? 82 : 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 5),
              Container(
                width: selected ? 22 : 8,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _historyCard(Meeting meeting, {required bool cancelled}) {
    final expanded = _expandedIds.contains(meeting.id);
    final name = meeting.studentName?.trim().isNotEmpty == true
        ? meeting.studentName!.trim()
        : 'Student';
    final initials = name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final department = meeting.facultyDept
        .replaceAll('Dept of ', '')
        .trim()
        .toUpperCase();
    final plannedDate = _requestedDate(meeting);

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
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE7E7E7),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
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
                            style: const TextStyle(fontSize: 11, color: _ink),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD0D0D0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Container(width: 2, height: 22, color: _muted),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        meeting.purpose,
                        maxLines: expanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: _ink),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_up,
                      size: 21,
                      color: _ink,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                if (cancelled)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
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
                        _detail(Icons.access_time, meeting.time!),
                      if (meeting.location?.isNotEmpty == true)
                        _detail(Icons.location_on_outlined, meeting.location!),
                    ],
                  ),
                if (expanded && meeting.denialReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  _detail(Icons.info_outline, meeting.denialReason!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _datePill(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(
          color: label == 'Cancelled on'
              ? const Color(0xFFEBA6F2)
              : const Color(0xFFCCCCCC),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$label : ${date == null ? 'Date unavailable' : DateFormat('MMM dd').format(date)}',
        style: const TextStyle(fontSize: 10, color: _muted),
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: _muted),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontSize: 11, color: _muted)),
    ],
  );
}
