import '../auth_service.dart';

/// Represents a user account stored in the system.
class UserModel {
  final String username;
  final String password;
  final UserRole role;
  final String displayName;
  final String email;
  final String? department;
  final String? studentId;
  final String? designation;

  const UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
    required this.email,
    this.department,
    this.studentId,
    this.designation,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'role': role.index,
    'displayName': displayName,
    'email': email,
    'department': department,
    'studentId': studentId,
    'designation': designation,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    username: json['username'] as String,
    password: json['password'] as String,
    role: UserRole.values[json['role'] as int],
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    department: json['department'] as String?,
    studentId: json['studentId'] as String?,
    designation: json['designation'] as String?,
  );
}
