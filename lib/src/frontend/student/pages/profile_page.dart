import 'package:flutter/material.dart';
import '../theme/student_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: StudentColors.cardBlue,
                child: Icon(Icons.person, size: 50, color: StudentColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Thoufik', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Student ID: 2025CS101', style: TextStyle(color: StudentColors.mutedInk)),
            const SizedBox(height: 32),
            _buildProfileOption(Icons.settings_outlined, 'Settings'),
            _buildProfileOption(Icons.help_outline, 'Help & Support'),
            _buildProfileOption(Icons.logout, 'Logout', isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : StudentColors.ink),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : StudentColors.ink, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
