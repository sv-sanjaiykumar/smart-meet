import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Persists student profile data (name, student ID, department, settings) to
/// SharedPreferences under a per-user key.
class StudentProfileService {
  static const String _prefix = 'smart_meet_student_profile_';
  static const String _settingsPrefix = 'smart_meet_student_settings_';

  String _profileKey(String username) =>
      '$_prefix${username.toLowerCase()}';

  String _settingsKey(String username) =>
      '$_settingsPrefix${username.toLowerCase()}';

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Returns the student's editable profile fields.
  ///
  /// Prioritizes live data from Firestore [UserModel], falling back to
  /// local cache or defaults.
  Future<Map<String, String>> getProfile(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(username));

    // Load the canonical user from Firestore via AuthService.
    final user = await AuthService().getCurrentUser();
    final defaults = <String, String>{
      'name': (user?.displayName != null && user!.displayName.isNotEmpty)
          ? user.displayName
          : _formatUsername(username),
      'studentId': user?.studentId ?? '',
      'department': user?.department ?? '',
      'email': (user?.email != null && user!.email.isNotEmpty)
          ? user.email
          : username,
      'year': user?.year ?? '',
      'section': user?.section ?? '',
    };

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final key in defaults.keys) {
          if (defaults[key]!.isEmpty) {
            final value = decoded[key];
            if (value is String && value.isNotEmpty) {
              defaults[key] = value;
            }
          }
        }
      } on FormatException {
        await prefs.remove(_profileKey(username));
      }
    }

    // Keep local cache synchronized with resolved values
    await prefs.setString(_profileKey(username), jsonEncode(defaults));

    return defaults;
  }

  /// Saves [updates] for [username] to Firestore DB and updates local cache.
  Future<void> saveProfile(
    String username,
    Map<String, String> updates,
  ) async {
    final existing = await getProfile(username);
    final merged = {...existing, ...updates};

    // 1. Update Firestore DB and sync Auth display name
    final currentUser = await AuthService().getCurrentUser();
    final targetUid = currentUser?.uid ?? username;
    await AuthService().updateUserProfile(targetUid, updates);

    // 2. Cache locally in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(username), jsonEncode(merged));
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Returns student-specific settings.
  Future<Map<String, bool>> getSettings(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey(username));
    const defaults = <String, bool>{
      'notifications': true,
      'emailAlerts': false,
      'darkMode': false,
    };
    if (raw == null || raw.isEmpty) return Map.from(defaults);
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return defaults.map(
        (key, value) => MapEntry(key, (decoded[key] as bool?) ?? value),
      );
    } on FormatException {
      return Map.from(defaults);
    }
  }

  /// Saves a single setting value.
  Future<void> setSetting(
    String username,
    String key,
    bool value,
  ) async {
    final settings = await getSettings(username);
    settings[key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey(username), jsonEncode(settings));
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _formatUsername(String username) => username
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}
