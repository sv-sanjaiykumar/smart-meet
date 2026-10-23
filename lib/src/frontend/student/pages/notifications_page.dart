import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/auth_service.dart';
import '../../../backend/notification_service.dart';
import '../theme/student_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notifService = NotificationService();
  final AuthService _authService = AuthService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = await _authService.getCurrentUsername();
    if (!mounted) return;
    _username = username;
    if (username == null) {
      setState(() => _isLoading = false);
      return;
    }
    final notifs = await _notifService.getNotifications(username);
    if (!mounted) return;
    setState(() {
      _notifications = notifs;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    if (_username == null) return;
    await _notifService.markAllRead(_username!);
    await _load();
  }

  Future<void> _clearAll() async {
    if (_username == null) return;
    await _notifService.clearAll(_username!);
    await _load();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

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
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: StudentColors.ink,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: StudentColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Clear all',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline, color: StudentColors.mutedInk),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 72,
            color: StudentColors.mutedInk.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: StudentColors.mutedInk,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You'll be notified when faculty respond\nto your meeting requests.",
            textAlign: TextAlign.center,
            style: TextStyle(color: StudentColors.mutedInk, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AppNotification notif) {
    final (Color bg, Color border, IconData icon, Color iconColor) =
        switch (notif.type) {
      NotificationType.accepted => (
          const Color(0xFFE8F5E9),
          const Color(0xFF81C784),
          Icons.check_circle_outline,
          const Color(0xFF2E7D32),
        ),
      NotificationType.rejected => (
          const Color(0xFFFFEBEE),
          const Color(0xFFEF9A9A),
          Icons.cancel_outlined,
          const Color(0xFFC62828),
        ),
      NotificationType.newRequest => (
          const Color(0xFFE3F2FD),
          const Color(0xFF90CAF9),
          Icons.assignment_outlined,
          const Color(0xFF1565C0),
        ),
      NotificationType.reminder => (
          const Color(0xFFFFF8E1),
          const Color(0xFFFFCC80),
          Icons.alarm_outlined,
          const Color(0xFFE65100),
        ),
      NotificationType.system => (
          const Color(0xFFF3E5F5),
          const Color(0xFFCE93D8),
          Icons.info_outline,
          const Color(0xFF6A1B9A),
        ),
    };

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead && _username != null) {
          await _notifService.markRead(_username!, notif.id);
          await _load();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isRead
                ? Colors.black.withValues(alpha: 0.05)
                : border.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notif.isRead ? Colors.grey[100] : bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: notif.isRead ? Colors.grey[200]! : border,
                ),
              ),
              child: Icon(icon, color: notif.isRead ? Colors.grey : iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 15,
                            color: StudentColors.ink,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: StudentColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      color: StudentColors.mutedInk,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notif.createdAt),
                    style: TextStyle(
                      color: StudentColors.mutedInk.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM, h:mm a').format(date);
  }
}
