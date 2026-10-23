import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_model.dart';

export 'models/user_model.dart' show UserModel;

enum UserRole { student, staff, admin }

class AuthResult {
  const AuthResult({
    required this.isSuccess,
    required this.role,
    required this.message,
    this.user,
  });

  final bool isSuccess;
  final UserRole? role;
  final String message;
  final UserModel? user;
}

/// Manages authentication for Smart Meet.
///
/// Accounts are seeded from [_seedAccounts] on first launch and persisted to
/// SharedPreferences so future sign-ins work without a network call.
class AuthService {
  // ── storage keys ──────────────────────────────────────────────────────────
  static const String _sessionKey = 'smart_meet_user_session';
  static const String _usersKey = 'smart_meet_users';

  // ── seed accounts ─────────────────────────────────────────────────────────
  static final List<UserModel> _seedAccounts = [
    // ── Students ──────────────────────────────────────────────────────────
    const UserModel(
      username: 'student',
      password: 'student123',
      role: UserRole.student,
      displayName: 'Thoufik',
      email: 'thoufik@college.edu',
      department: 'CSE',
      studentId: '2025CS101',
    ),
    const UserModel(
      username: 'priya',
      password: 'priya123',
      role: UserRole.student,
      displayName: 'Priya Nair',
      email: 'priya@college.edu',
      department: 'ECE',
      studentId: '2025EC202',
    ),
    const UserModel(
      username: 'arjun',
      password: 'arjun123',
      role: UserRole.student,
      displayName: 'Arjun Menon',
      email: 'arjun@college.edu',
      department: 'AI&ML',
      studentId: '2025AI303',
    ),
    // ── Staff ─────────────────────────────────────────────────────────────
    const UserModel(
      username: 'staff',
      password: 'staff123',
      role: UserRole.staff,
      displayName: 'Anwar Raja',
      email: 'anwar@college.edu',
      department: 'ECE',
      designation: 'Assistant Professor',
    ),
    const UserModel(
      username: 'anushka',
      password: 'anushka123',
      role: UserRole.staff,
      displayName: 'Anushka Sharma',
      email: 'anushka@college.edu',
      department: 'CSE',
      designation: 'Associate Professor',
    ),
    const UserModel(
      username: 'lakshmanan',
      password: 'lak123',
      role: UserRole.staff,
      displayName: 'Prof. Lakshmanan',
      email: 'lakshmanan@college.edu',
      department: 'AI&ML',
      designation: 'Professor',
    ),
    const UserModel(
      username: 'admin',
      password: 'admin123',
      role: UserRole.admin,
      displayName: 'Smart Meet Admin',
      email: 'admin@college.edu',
    ),
  ];

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Ensures seed accounts exist in SharedPreferences.
  Future<void> _ensureUsersSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setString(
        _usersKey,
        jsonEncode(_seedAccounts.map((u) => u.toJson()).toList()),
      );
      return;
    }

    try {
      final users = (jsonDecode(raw) as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!users.any((user) => user.role == UserRole.admin)) {
        users.add(_seedAccounts.last);
        await prefs.setString(
          _usersKey,
          jsonEncode(users.map((user) => user.toJson()).toList()),
        );
      }
    } on FormatException {
      await prefs.setString(
        _usersKey,
        jsonEncode(_seedAccounts.map((u) => u.toJson()).toList()),
      );
    }
  }

  /// Loads all user accounts from storage.
  Future<List<UserModel>> _loadUsers() async {
    await _ensureUsersSeeded();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      await prefs.remove(_usersKey);
      return _seedAccounts;
    }
  }

  // ── public API ────────────────────────────────────────────────────────────

  /// Authenticates [username] with [password].
  Future<AuthResult> login(String username, String password) async {
    final normalized = username.trim().toLowerCase();
    final normalizedPw = password.trim();

    if (normalized.isEmpty || normalizedPw.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Please enter both username and password.',
      );
    }

    final users = await _loadUsers();
    final user = users.cast<UserModel?>().firstWhere(
      (u) => u!.username.toLowerCase() == normalized,
      orElse: () => null,
    );

    if (user == null) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Account not found. Please check your credentials.',
      );
    }

    if (user.password != normalizedPw) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Incorrect password. Please try again.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, normalized);

    return AuthResult(
      isSuccess: true,
      role: user.role,
      message: 'Login successful',
      user: user,
    );
  }

  /// Returns the [UserRole] of the currently logged-in user, or null.
  Future<UserRole?> getCurrentRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }

  /// Returns the username string of the current session, or null.
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  /// Returns the full [UserModel] for the current session, or null.
  Future<UserModel?> getCurrentUser() async {
    final username = await getCurrentUsername();
    if (username == null) return null;

    final users = await _loadUsers();
    return users.cast<UserModel?>().firstWhere(
      (u) => u!.username.toLowerCase() == username.toLowerCase(),
      orElse: () => null,
    );
  }

  /// Returns all faculty accounts in the system.
  Future<List<UserModel>> getAllFaculty() async {
    final users = await _loadUsers();
    return users.where((u) => u.role == UserRole.staff).toList();
  }

  /// Returns all student accounts in the system.
  Future<List<UserModel>> getAllStudents() async {
    final users = await _loadUsers();
    return users.where((u) => u.role == UserRole.student).toList();
  }

  /// Returns staff and student accounts to the signed-in administrator.
  Future<List<UserModel>> getManagedAccounts() async {
    if (await getCurrentRole() != UserRole.admin) {
      throw StateError('Only administrators can view managed accounts.');
    }
    final users = await _loadUsers();
    return users.where((user) => user.role != UserRole.admin).toList();
  }

  /// Creates a staff or student account for the signed-in administrator.
  Future<AuthResult> createManagedAccount({
    required String username,
    required String password,
    required UserRole role,
    required String displayName,
    required String email,
    required String department,
    String? studentId,
    String? designation,
  }) async {
    if (await getCurrentRole() != UserRole.admin) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Only administrators can create accounts.',
      );
    }
    if (role == UserRole.admin) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Only staff and student accounts can be created here.',
      );
    }

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = displayName.trim();
    final normalizedDepartment = department.trim();
    final normalizedPassword = password.trim();
    if (normalizedUsername.length < 3 ||
        normalizedPassword.length < 6 ||
        normalizedName.isEmpty ||
        !normalizedEmail.contains('@') ||
        normalizedDepartment.isEmpty ||
        (role == UserRole.student && (studentId?.trim().isNotEmpty != true)) ||
        (role == UserRole.staff && (designation?.trim().isNotEmpty != true))) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Please provide valid details for all required fields.',
      );
    }

    final users = await _loadUsers();
    if (users.any(
      (user) =>
          user.username.toLowerCase() == normalizedUsername ||
          user.email.toLowerCase() == normalizedEmail,
    )) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'That username or email is already in use.',
      );
    }

    final account = UserModel(
      username: normalizedUsername,
      password: normalizedPassword,
      role: role,
      displayName: normalizedName,
      email: normalizedEmail,
      department: normalizedDepartment,
      studentId: role == UserRole.student ? studentId?.trim() : null,
      designation: role == UserRole.staff ? designation?.trim() : null,
    );
    users.add(account);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );

    return AuthResult(
      isSuccess: true,
      role: role,
      message: 'Account created successfully.',
      user: account,
    );
  }

  /// Updates a user's profile fields (name, department, designation, etc.)
  /// and persists the changes. Does not allow changing username or role.
  Future<void> updateUserProfile(String username, Map<String, String> updates) async {
    await _ensureUsersSeeded();
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers();
    final index = users.indexWhere(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
    );
    if (index == -1) return;

    final old = users[index];
    users[index] = UserModel(
      username: old.username,
      password: old.password,
      role: old.role,
      displayName: updates['name'] ?? old.displayName,
      email: old.email, // email (login id) is immutable
      department: updates['department'] ?? old.department,
      studentId: updates['studentId'] ?? old.studentId,
      designation: updates['designation'] ?? old.designation,
    );

    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, encoded);
  }

  /// Clears the current session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
