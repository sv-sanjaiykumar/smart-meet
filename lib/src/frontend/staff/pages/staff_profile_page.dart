import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../backend/auth_service.dart';
import '../../login/login_page.dart';

class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF888888);
  static const _accent = Color(0xFFBFC4FF);

  String? _username;
  Map<String, String> _details = {};
  bool _isLoading = true;
  bool _showAccount = false;
  bool _notificationsEnabled = true;

  String get _profileKey => 'smart_meet_staff_profile_${_username ?? 'staff'}';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = AuthService();
    final username = await authService.getCurrentUsername() ?? 'staff';
    final prefs = await SharedPreferences.getInstance();
    final savedProfile = prefs.getString(_profileKeyFor(username));
    final savedSettings = prefs.getBool('staff_notifications_enabled') ?? true;
    final defaults = <String, String>{
      'name': username.toLowerCase() == 'staff'
          ? 'Anwar Raja'
          : _displayName(username),
      'email': username,
      'department': username.toLowerCase() == 'staff' ? 'ECE' : '',
      'designation': username.toLowerCase() == 'staff'
          ? 'Assistant Professor'
          : 'Faculty',
      'specialization': username.toLowerCase() == 'staff'
          ? 'MicroControllers'
          : '',
      'status': 'Active for meeting',
    };

    if (savedProfile != null) {
      try {
        final decoded = jsonDecode(savedProfile) as Map<String, dynamic>;
        for (final key in defaults.keys) {
          final value = decoded[key];
          if (value is String) defaults[key] = value;
        }
      } on FormatException {
        await prefs.remove(_profileKeyFor(username));
      }
    }

    if (!mounted) return;
    setState(() {
      _username = username;
      _details = defaults;
      _notificationsEnabled = savedSettings;
      _isLoading = false;
    });
  }

  String _profileKeyFor(String username) =>
      'smart_meet_staff_profile_$username';

  String _displayName(String username) => username
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_details));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile details saved')));
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Colors.white;
    const primary = _ink;
    const secondary = _muted;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ColoredBox(
      color: background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 16, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: _showAccount ? 'Back to profile' : 'Back to home',
                  onPressed: () {
                    if (_showAccount) {
                      setState(() => _showAccount = false);
                    } else {
                      widget.onBack();
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: primary),
                ),
                Expanded(
                  child: Text(
                    _showAccount ? 'Account' : 'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 104),
              child: _showAccount
                  ? _buildAccount(background, primary, secondary)
                  : _buildProfile(background, primary, secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(Color background, Color primary, Color secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 146,
          padding: const EdgeInsets.fromLTRB(20, 20, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF7196DA), Color(0xFF9AB6E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentorship Made',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Effortless.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Let AI plan, you educate!',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: const Color(0xFFD1DDFC),
                  borderRadius: BorderRadius.circular(15),
                  child: IconButton(
                    tooltip: 'Mentorship information',
                    onPressed: () =>
                        _showMessage('Mentorship tools are coming soon.'),
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF5879B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('staff-account-row'),
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _showAccount = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFF0F0F0),
                    child: Icon(Icons.person_outline, size: 27, color: _muted),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _details['name'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        Text(
                          'Personal Info',
                          style: TextStyle(fontSize: 13, color: secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Open account details',
                      onPressed: () => setState(() => _showAccount = true),
                      icon: Icon(Icons.chevron_right, color: primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _settingRow(
          icon: Icons.notifications_none,
          title: 'Notifications',
          primary: primary,
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
            _setPreference('staff_notifications_enabled', value);
          },
        ),
        Material(
          color: background,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0F0F0),
              child: Icon(Icons.support_agent, color: _muted),
            ),
            title: Text(
              'Help & Support',
              style: TextStyle(color: primary, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMessage(
              'Contact your Smart Meet administrator for support.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required Color primary,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0F0F0),
          child: Icon(icon, color: _muted),
        ),
        title: Text(
          title,
          style: TextStyle(color: primary, fontWeight: FontWeight.w500),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: _accent,
        ),
      ),
    );
  }

  Widget _buildAccount(Color background, Color primary, Color secondary) {
    final fields = [
      _accountField('Name', 'name', primary, secondary),
      _accountField(
        'Email / Login ID',
        'email',
        primary,
        secondary,
        readOnly: true,
      ),
      _accountField('Dep', 'department', primary, secondary),
      _accountField('Designation', 'designation', primary, secondary),
      _accountField('Specialization', 'specialization', primary, secondary),
      _statusField(primary, secondary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Column(
            children: [
              Text('Photo', style: TextStyle(color: secondary, fontSize: 14)),
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFF0F0F0),
                child: Icon(
                  Icons.person_outline,
                  size: 42,
                  color: Color(0xFFB8B8B8),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showMessage(
                  'Photo upload is not available in this local demo.',
                ),
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Upload Image'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9FA8FF),
                ),
              ),
            ],
          ),
        ),
        ...fields,
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 17),
              label: const Text('Logout'),
              style: TextButton.styleFrom(foregroundColor: _muted),
            ),
            FilledButton(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _ink,
                minimumSize: const Size(56, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.check),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountField(
    String label,
    String key,
    Color primary,
    Color secondary, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: secondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('staff-profile-$key'),
              initialValue: _details[key] ?? '',
              readOnly: readOnly,
              onChanged: (value) => _details[key] = value,
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD2D2D2)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusField(Color primary, Color secondary) {
    const statuses = ['Active for meeting', 'Unavailable', 'On leave'];
    final status = statuses.contains(_details['status'])
        ? _details['status']
        : statuses.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              'Status',
              style: TextStyle(color: secondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD2D2D2)),
                ),
              ),
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: statuses
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _details['status'] = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
