import '../auth_service.dart';

/// Represents a user account stored in Firestore.
class UserModel {
  /// Firebase Auth UID (also the Firestore document ID).
  final String uid;
  final String username;
  /// Password is never stored on the client; kept as empty string.
  final String password;
  final UserRole role;
  final String displayName;
  final String email;
  final String? department;
  final String? studentId;
  final String? designation;
  final String? year;
  final String? section;

  const UserModel({
    required this.uid,
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
    required this.email,
    this.department,
    this.studentId,
    this.designation,
    this.year,
    this.section,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'role': role.index,
    'displayName': displayName,
    'email': email,
    'department': department,
    'studentId': studentId,
    'designation': designation,
    'year': year,
    'section': section,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String? ?? '',
    username: json['username'] as String,
    password: '',
    role: UserRole.values[json['role'] as int],
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    department: json['department'] as String?,
    studentId: json['studentId'] as String?,
    designation: json['designation'] as String?,
    year: json['year'] as String?,
    section: json['section'] as String?,
  );
}

