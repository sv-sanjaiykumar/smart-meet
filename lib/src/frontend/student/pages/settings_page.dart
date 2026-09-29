import 'package:flutter/material.dart';

import '../../../backend/auth_service.dart';
import '../../login/login_page.dart';
import '../theme/student_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: AppBar(
        backgroundColor: StudentColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('General'),
          _buildSettingItem(
            context,
            icon: Icons.person_outline,
            title: 'Account Settings',
            subtitle: 'Profile, Email, Password',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Push, Email notifications',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & Privacy'),
          _buildSettingItem(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            subtitle: 'Permissions, Two-factor auth',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQ, Contact us',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'About Smart Meet',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: StudentColors.mutedInk,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: StudentColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: StudentColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: StudentColors.mutedInk, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

}
