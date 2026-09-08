import 'package:flutter/material.dart';
import '../theme/student_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: StudentColors.softBlue,
                  child: Icon(Icons.notifications, color: StudentColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meeting Accepted', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Prof. Lakshmanan accepted your request.', style: TextStyle(fontSize: 12, color: StudentColors.mutedInk)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
