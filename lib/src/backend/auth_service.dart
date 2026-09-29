import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, staff }

class AuthResult {
  const AuthResult({
    required this.isSuccess,
    required this.role,
    required this.message,
  });

  final bool isSuccess;
  final UserRole? role;
  final String message;
}

class AuthService {
  static const String _key = 'smart_meet_user_session';

  static const Map<String, Map<String, dynamic>> _defaultCredentials = {
    'student': {'password': 'student123', 'role': UserRole.student},
    'staff': {'password': 'staff123', 'role': UserRole.staff},
  };

  Future<AuthResult> login(String username, String password) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Please enter both email or roll number and password.',
      );
    }

    final credential = _defaultCredentials[normalizedUsername.toLowerCase()];

    if (credential == null) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Account not found. Please check your credentials.',
      );
    }

    final savedPassword = credential['password'] as String;
    if (normalizedPassword != savedPassword) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Incorrect password. Please try again.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalizedUsername.toLowerCase());

    return AuthResult(
      isSuccess: true,
      role: credential['role'] as UserRole,
      message: 'Login successful',
    );
  }

  Future<UserRole?> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_key)?.toLowerCase();

    if (username == null) return null;

    final role = _defaultCredentials[username]?['role'] as UserRole?;
    return role;
  }

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
