import 'package:flutter/material.dart';
import '../theme/student_theme.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: StudentColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No events scheduled for today', style: TextStyle(color: StudentColors.mutedInk)),
          ],
        ),
      ),
    );
  }
}
