import 'package:flutter/material.dart';

import '../../../backend/auth_service.dart';
import '../../../backend/student_profile_service.dart';
import '../../login/login_page.dart';
import '../theme/student_theme.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final StudentProfileService _profileService = StudentProfileService();

  Map<String, String> _profile = {};
  bool _isLoading = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await _authService.getCurrentUsername();
    if (!mounted) return;
    if (username == null) {
      setState(() => _isLoading = false);
      return;
    }
    final profile = await _profileService.getProfile(username);
    if (!mounted) return;
    setState(() {
      _username = username;
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _profile['name'] ?? 'Student';
    final studentId = _profile['studentId'] ?? '';
    final department = _profile['department'] ?? '';

    return Scaffold(
      backgroundColor: StudentColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: StudentColors.cardBlue,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: StudentColors.ink,
              ),
            ),
            if (studentId.isNotEmpty || department.isNotEmpty)
              Text(
                [if (studentId.isNotEmpty) 'ID: $studentId', if (department.isNotEmpty) department]
                    .join(' · '),
                style: const TextStyle(color: StudentColors.mutedInk),
              ),
            const SizedBox(height: 32),
            _buildProfileOption(
              context,
              Icons.settings_outlined,
              'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            _buildProfileOption(context, Icons.help_outline, 'Help & Support'),
            _buildProfileOption(
              context,
              Icons.logout,
              'Logout',
              isDestructive: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : StudentColors.ink,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : StudentColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
