import 'package:flutter/material.dart';

import '../../../backend/auth_service.dart';
import '../../../backend/meeting_service.dart';
import '../../../backend/student_profile_service.dart';
import '../../login/login_page.dart';
import '../models/meeting.dart';
import '../theme/student_theme.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfilePage({super.key, this.onProfileUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final StudentProfileService _profileService = StudentProfileService();
  final MeetingService _meetingService = MeetingService();

  Map<String, String> _profile = {};
  Map<String, bool> _settings = {};
  List<Meeting> _studentMeetings = [];
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
    final settings = await _profileService.getSettings(username);
    final meetings = await _meetingService.getMeetingsForCurrentStudent();

    if (!mounted) return;
    setState(() {
      _username = username;
      _profile = profile;
      _settings = settings;
      _studentMeetings = meetings;
      _isLoading = false;
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    if (_username == null) return;
    setState(() {
      _settings[key] = value;
    });
    await _profileService.setSetting(_username!, key, value);
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from your Smart Meet account?',
          style: TextStyle(color: StudentColors.mutedInk, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: StudentColors.mutedInk),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await _authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _profile['name'] ?? '');
    final idController = TextEditingController(text: _profile['studentId'] ?? '');
    String selectedDept = _profile['department']?.trim() ?? 'CSE';
    if (selectedDept.isEmpty) selectedDept = 'CSE';
    String selectedYear = _profile['year']?.trim() ?? '3rd Year';
    if (selectedYear.isEmpty) selectedYear = '3rd Year';
    String selectedSection = _profile['section']?.trim() ?? 'A';
    if (selectedSection.isEmpty) selectedSection = 'A';

    const depts = ['CSE', 'ECE', 'MECH', 'CIVIL', 'IT', 'AIDS'];
    const years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    const sections = ['A', 'B', 'C'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: StudentColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: StudentColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: StudentColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Update your student information',
                              style: TextStyle(
                                fontSize: 13,
                                color: StudentColors.mutedInk,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: nameController,
                      hint: 'e.g. Kumar',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Student Roll / ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: idController,
                      hint: 'e.g. 21CS042',
                      icon: Icons.fingerprint,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Department',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: depts.map((d) {
                        final isSelected = selectedDept == d;
                        return ChoiceChip(
                          label: Text(d),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedDept = d);
                          },
                          selectedColor: StudentColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : StudentColors.ink,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? StudentColors.primary
                                : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Academic Year',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: years.map((y) {
                        final isSelected = selectedYear == y;
                        return ChoiceChip(
                          label: Text(y),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedYear = y);
                          },
                          selectedColor: StudentColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : StudentColors.ink,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? StudentColors.primary
                                : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Section',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StudentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: sections.map((s) {
                        final isSelected = selectedSection == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text('Section $s'),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => selectedSection = s);
                              }
                            },
                            selectedColor: StudentColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : StudentColors.ink,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? StudentColors.primary
                                  : Colors.grey[300]!,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: StudentColors.mutedInk),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final updatedName = nameController.text.trim();
                              final updatedId = idController.text.trim();
                              if (_username != null) {
                                final updates = {
                                  if (updatedName.isNotEmpty)
                                    'name': updatedName,
                                  if (updatedId.isNotEmpty)
                                    'studentId': updatedId,
                                  'department': selectedDept,
                                  'year': selectedYear,
                                  'section': selectedSection,
                                };
                                await _profileService.saveProfile(
                                  _username!,
                                  updates,
                                );
                                await _loadProfile();
                                widget.onProfileUpdated?.call();
                              }
                              if (bottomSheetContext.mounted) {
                                Navigator.pop(bottomSheetContext);
                              }
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully!'),
                                    backgroundColor: StudentColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StudentColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: StudentColors.primary, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showGuidelinesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: StudentColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rule_folder_outlined,
                    color: StudentColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Guidelines & FAQ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: StudentColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Best practices for meeting faculty',
                      style: TextStyle(
                        fontSize: 13,
                        color: StudentColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildGuidelineItem(
              Icons.schedule,
              'Submit in Advance',
              'Send meeting requests at least 24 hours prior to allow faculty time to schedule and allocate a cabin or lab.',
            ),
            const SizedBox(height: 14),
            _buildGuidelineItem(
              Icons.description_outlined,
              'Clear Purpose & Documents',
              'Specify your purpose accurately (Form Sign, Project Review, Doubts) and bring printed copies or ID cards as needed.',
            ),
            const SizedBox(height: 14),
            _buildGuidelineItem(
              Icons.access_time_outlined,
              'Punctuality & Venue',
              'Arrive at the designated cabin 5 minutes early. If unable to attend, cancel through the Requests tab.',
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StudentColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: StudentColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: StudentColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: StudentColors.mutedInk,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: StudentColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _profile['name']?.trim().isNotEmpty == true
        ? _profile['name']!
        : 'Student';
    final studentId = _profile['studentId']?.trim().isNotEmpty == true
        ? _profile['studentId']!
        : 'ID: Not Set';
    final department = _profile['department']?.trim().isNotEmpty == true
        ? _profile['department']!
        : 'CSE';
    final email = _profile['email']?.trim().isNotEmpty == true
        ? _profile['email']!
        : (_username ?? 'student@smartmeet.edu');
    final year = _profile['year']?.trim().isNotEmpty == true
        ? _profile['year']!
        : '3rd Year';
    final section = _profile['section']?.trim().isNotEmpty == true
        ? _profile['section']!
        : 'Sec A';

    final totalMeetings = _studentMeetings.length;
    final upcomingCount = _studentMeetings
        .where((m) => m.status == MeetingStatus.accepted)
        .length;
    final pendingCount = _studentMeetings
        .where((m) => m.status == MeetingStatus.pending)
        .length;

    final initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: StudentColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: StudentColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Student Account & Overview',
                          style: TextStyle(
                            fontSize: 13,
                            color: StudentColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _showEditProfileSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: StudentColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: StudentColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Hero Profile Card ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF3F8FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: StudentColors.primary.withValues(alpha: 0.09),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with edit badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  StudentColors.primary,
                                  Color(0xFFB8D8FE),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFE2EFFF),
                              child: Text(
                                initialLetter,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: StudentColors.primary,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showEditProfileSheet,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: StudentColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: StudentColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: StudentColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: StudentColors.mutedInk,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Pills row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: StudentColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school,
                                  size: 13,
                                  color: StudentColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  department,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: StudentColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 13,
                                  color: StudentColors.mutedInk,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  studentId,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: StudentColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Color(0xFF1CB059),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Student',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1CB059),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Activity Stats Row ──────────────────────────────────────
                const Text(
                  'Meeting Overview',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Upcoming',
                        count: upcomingCount,
                        icon: Icons.event_available_rounded,
                        color: StudentColors.primary,
                        bgColor: const Color(0xFFEEF5FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pending',
                        count: pendingCount,
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFF39C12),
                        bgColor: const Color(0xFFFEF6E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total',
                        count: totalMeetings,
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF8E44AD),
                        bgColor: const Color(0xFFF7EEFA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Academic Information Card ───────────────────────────────
                const Text(
                  'Academic Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.apartment_rounded,
                        'Campus / University',
                        'Smart Meet Engineering College',
                      ),
                      const Divider(height: 22, color: Color(0xFFF0F2F6)),
                      _buildDetailRow(
                        Icons.school_outlined,
                        'Department',
                        department == 'CSE'
                            ? 'Computer Science & Engineering'
                            : department,
                      ),
                      const Divider(height: 22, color: Color(0xFFF0F2F6)),
                      _buildDetailRow(
                        Icons.calendar_month_outlined,
                        'Year & Semester',
                        '$year • $section',
                      ),
                      const Divider(height: 22, color: Color(0xFFF0F2F6)),
                      _buildDetailRow(
                        Icons.numbers_outlined,
                        'Student Roll ID',
                        studentId,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Preferences & Settings ──────────────────────────────────
                const Text(
                  'Preferences & Account',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: StudentColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Meeting Notifications',
                        subtitle: 'Alerts when faculty accepts or updates',
                        value: _settings['notifications'] ?? true,
                        onChanged: (val) => _toggleSetting('notifications', val),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F6)),
                      _buildSwitchOption(
                        icon: Icons.mark_email_unread_outlined,
                        title: 'Email Alerts',
                        subtitle: 'Send meeting confirmations to inbox',
                        value: _settings['emailAlerts'] ?? false,
                        onChanged: (val) => _toggleSetting('emailAlerts', val),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F6)),
                      _buildNavigationOption(
                        icon: Icons.tune_rounded,
                        title: 'App Settings',
                        subtitle: 'Theme, security, and permissions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F2F6)),
                      _buildNavigationOption(
                        icon: Icons.help_outline_rounded,
                        title: 'Meeting Guidelines & FAQ',
                        subtitle: 'Tips for scheduling with faculty',
                        onTap: _showGuidelinesSheet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sign Out Button ─────────────────────────────────────────
                Material(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => _logout(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD4D4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Smart Meet v1.0.0 • Connected to Campus Cloud',
                    style: TextStyle(
                      fontSize: 11,
                      color: StudentColors.mutedInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: StudentColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: StudentColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: StudentColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: StudentColors.mutedInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StudentColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: StudentColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StudentColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: StudentColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: StudentColors.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: StudentColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: StudentColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: StudentColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: StudentColors.mutedInk,
            ),
          ],
        ),
      ),
    );
  }
}
