import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../student/models/meeting.dart';

class StaffRequestsPage extends StatefulWidget {
  const StaffRequestsPage({
    super.key,
    required this.meetings,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  final List<Meeting> meetings;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Meeting meeting, MeetingStatus status)
  onStatusChanged;

  @override
  State<StaffRequestsPage> createState() => _StaffRequestsPageState();
}

class _StaffRequestsPageState extends State<StaffRequestsPage>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF777777);
  static const _pink = Color(0xFFF8DDFB);

  late final TabController _tabController;
  final Set<String> _expandedRequests = {};
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime? _requestedAt(Meeting meeting) {
    final idTimestamp = RegExp(r'req_(\d+)').firstMatch(meeting.id)?.group(1);
    if (idTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(idTimestamp));
    }
    try {
      return DateFormat('d MMM, h:mm a').parse(meeting.requestedAt);
    } on FormatException {
      return null;
    }
  }

  bool _isNew(Meeting meeting) {
    if (meeting.status != MeetingStatus.pending) return false;
    final requestedAt = _requestedAt(meeting);
    if (requestedAt == null) return false;
    final age = DateTime.now().difference(requestedAt);
    return !age.isNegative && age.inHours < 24;
  }

  List<Meeting> _meetingsForTab(int index) {
    final filtered = widget.meetings.where((meeting) {
      switch (index) {
        case 1:
          return _isNew(meeting);
        case 2:
          return meeting.status == MeetingStatus.accepted;
        case 3:
          return meeting.status == MeetingStatus.pending && !_isNew(meeting);
        case 4:
          return meeting.status == MeetingStatus.rejected;
        default:
          return true;
      }
    }).toList();
    filtered.sort((a, b) {
      final aTime = _requestedAt(a) ?? DateTime(1970);
      final bTime = _requestedAt(b) ?? DateTime(1970);
      return _newestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Requests',
          style: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),
        TabBar(
          controller: _tabController,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          labelColor: _ink,
          unselectedLabelColor: _muted,
          indicatorColor: _ink,
          indicatorWeight: 2,
          dividerColor: const Color(0xFFBDBDBD),
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'New'),
            Tab(text: 'Accepted'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Due today',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              PopupMenuButton<bool>(
                tooltip: 'Sort requests',
                initialValue: _newestFirst,
                onSelected: (newestFirst) =>
                    setState(() => _newestFirst = newestFirst),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: true, child: Text('Newest first')),
                  PopupMenuItem(value: false, child: Text('Oldest first')),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
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
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(5, _buildTabList),
          ),
        ),
      ],
    );
  }

  Widget _buildTabList(int tabIndex) {
    final meetings = _meetingsForTab(tabIndex);
    if (meetings.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 90),
          children: const [
            Icon(Icons.inbox_outlined, size: 42, color: Color(0xFFB8B8B8)),
            SizedBox(height: 12),
            Center(
              child: Text(
                'No requests in this category',
                style: TextStyle(color: _muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        itemCount: meetings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRequestCard(meetings[index]),
      ),
    );
  }

  Widget _buildRequestCard(Meeting meeting) {
    final expanded = _expandedRequests.contains(meeting.id);
    final isNew = _isNew(meeting);
    final statusColor = switch (meeting.status) {
      MeetingStatus.accepted => const Color(0xFF17C964),
      MeetingStatus.rejected => const Color(0xFFFF625A),
      MeetingStatus.pending when isNew => const Color(0xFF3699F5),
      _ => const Color(0xFFFFA726),
    };
    final statusLabel = switch (meeting.status) {
      MeetingStatus.accepted => 'Accepted',
      MeetingStatus.rejected => 'Rejected',
      MeetingStatus.pending when isNew => 'New',
      MeetingStatus.pending => 'Pending',
      MeetingStatus.completed => 'Completed',
    };
    final initials = meeting.studentName?.trim().isNotEmpty == true
        ? meeting.studentName!
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase()
        : 'S';

    return Material(
      color: isNew ? _pink : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() {
          expanded
              ? _expandedRequests.remove(meeting.id)
              : _expandedRequests.add(meeting.id);
        }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
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
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.studentName ?? 'Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          meeting.id.replaceFirst('req_', '').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ink, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _departmentBadge(meeting.facultyDept),
                  const SizedBox(width: 8),
                  _statusBadge(statusLabel, statusColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(width: 2, height: 21, color: _muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      meeting.purpose,
                      maxLines: expanded ? 4 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontSize: 14),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                    color: _ink,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (meeting.time != null && meeting.time!.isNotEmpty)
                      _detail(Icons.access_time, meeting.time!),
                    if (meeting.location != null &&
                        meeting.location!.isNotEmpty)
                      _detail(Icons.location_on_outlined, meeting.location!),
                    _detail(Icons.schedule, meeting.requestedAt),
                    if (meeting.denialReason != null &&
                        meeting.denialReason!.isNotEmpty)
                      _detail(Icons.info_outline, meeting.denialReason!),
                  ],
                ),
              ],
              if (meeting.status == MeetingStatus.pending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SlideToAccept(
                      onAccepted: () => widget.onStatusChanged(
                        meeting,
                        MeetingStatus.accepted,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Reject request',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => widget.onStatusChanged(
                        meeting,
                        MeetingStatus.rejected,
                      ),
                      icon: const Icon(Icons.close, size: 20, color: _muted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _departmentBadge(String department) {
    final label = department.replaceAll('Dept of ', '').trim().toUpperCase();
    return Container(
      constraints: const BoxConstraints(maxWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(color: const Color(0xFFD6D6D6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFFB44CC6), fontSize: 10),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: _ink)),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: _muted)),
      ],
    );
  }
}

class _SlideToAccept extends StatefulWidget {
  const _SlideToAccept({required this.onAccepted});

  final Future<void> Function() onAccepted;

  @override
  State<_SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<_SlideToAccept> {
  double _dragOffset = 0;
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 32.0;
        const thumbSize = 26.0;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(116.0, 150.0)
            : 140.0;
        final maxOffset = width - thumbSize - 6;

        Future<void> finishDrag() async {
          if (_dragOffset >= maxOffset * 0.75 && !_isAccepting) {
            setState(() => _isAccepting = true);
            await widget.onAccepted();
          }
          if (mounted) setState(() => _dragOffset = 0);
        }

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(
              () => _dragOffset = (_dragOffset + details.delta.dx).clamp(
                0,
                maxOffset,
              ),
            );
          },
          onHorizontalDragEnd: (_) => finishDrag(),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7A9BC)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                const Center(
                  child: Text(
                    'slide to accept',
                    style: TextStyle(fontSize: 10, color: Color(0xFF292929)),
                  ),
                ),
                Positioned(
                  left: _dragOffset,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8DDFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
