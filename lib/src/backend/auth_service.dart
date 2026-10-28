import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models/user_model.dart';
import 'push_notification_service.dart';

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

/// Manages authentication for Smart Meet using Firebase Auth + Firestore.
///
/// Flow:
///  - Admin creates staff/student accounts (Firebase Auth user + Firestore doc).
///    Admin must supply their own password so the service can restore the
///    admin session after creating the new account.
///  - Staff/Students sign in with email + password via Firebase Auth.
///  - Role is stored in the Firestore 'users' collection.
class AuthService {
  static const String _usersCollection = 'users';

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _injectedAuth = auth,
        _injectedDb = db;

  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedDb;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Converts a Firestore role string to [UserRole].
  UserRole _roleFromString(String? raw) {
    switch (raw) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.student;
    }
  }

  /// Converts a [UserRole] to its Firestore string representation.
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.student:
        return 'student';
    }
  }

  /// Builds a [UserModel] from a Firestore document snapshot.
  UserModel _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      password: '',
      role: _roleFromString(data['role'] as String?),
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      department: data['department'] as String?,
      studentId: data['studentId'] as String?,
      designation: data['designation'] as String?,
      year: data['year'] as String?,
      section: data['section'] as String?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  // ── public API ────────────────────────────────────────────────────────────

  /// Returns the currently signed-in Firebase user, or null.
  User? get firebaseUser => _auth.currentUser;

  /// Signs in with [email] and [password] via Firebase Auth.
  Future<AuthResult> login(String email, String password) async {
    var normalizedEmail = email.trim().toLowerCase();
    final normalizedPw = password.trim();

    if (normalizedEmail.isEmpty || normalizedPw.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Please enter both email and password.',
      );
    }

    // Auto-complete username if user omitted domain
    if (!normalizedEmail.contains('@')) {
      normalizedEmail = '$normalizedEmail@smartmeet.edu';
    }

    try {
      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: normalizedPw,
        );
      } on FirebaseAuthException {
        // If user typed @smartmeet.com instead of @smartmeet.edu, seamlessly try @smartmeet.edu
        if (normalizedEmail.endsWith('@smartmeet.com')) {
          final eduEmail = normalizedEmail.replaceFirst(
            '@smartmeet.com',
            '@smartmeet.edu',
          );
          credential = await _auth.signInWithEmailAndPassword(
            email: eduEmail,
            password: normalizedPw,
          );
        } else {
          rethrow;
        }
      }

      final uid = credential.user?.uid;
      if (uid == null) {
        return const AuthResult(
          isSuccess: false,
          role: null,
          message: 'Authentication failed. Please try again.',
        );
      }

      final doc = await _db.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return const AuthResult(
          isSuccess: false,
          role: null,
          message: 'Account profile not found. Contact your administrator.',
        );
      }

      final userModel = _userFromDoc(doc);

      // Register device for push notifications
      try {
        await PushNotificationService().registerUserDevice(
          userModel.uid,
          role: userModel.role,
          username: userModel.username,
        );
      } catch (e) {
        debugPrint('⚠️ [FCM] Login device registration error: $e');
      }

      return AuthResult(
        isSuccess: true,
        role: userModel.role,
        message: 'Login successful',
        user: userModel,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('🔑 Login error: code=${e.code}, message=${e.message}');
      final msg = switch (e.code) {
        'user-not-found' =>
          'No account found with this email. Institutional emails end with @smartmeet.edu.',
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password. Note: institutional email ends with @smartmeet.edu.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'invalid-email' => 'Please enter a valid email address.',
        _ => 'Login failed: ${e.message ?? e.code}',
      };
      return AuthResult(isSuccess: false, role: null, message: msg);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        role: null,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Returns the [UserRole] of the currently signed-in user, or null.
  Future<UserRole?> getCurrentRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }

  /// Returns the email (login ID) of the current Firebase Auth session, or null.
  Future<String?> getCurrentUsername() async {
    return _auth.currentUser?.email;
  }

  /// Returns the full [UserModel] for the current Firebase session, or null.
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    try {
      final doc =
          await _db.collection(_usersCollection).doc(fbUser.uid).get();
      if (!doc.exists) return null;
      return _userFromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  /// Returns all faculty accounts stored in Firestore.
  Future<List<UserModel>> getAllFaculty() async {
    final snap = await _db
        .collection(_usersCollection)
        .where('role', isEqualTo: 'staff')
        .get();
    return snap.docs.map(_userFromDoc).toList();
  }

  /// Returns all student accounts stored in Firestore.
  Future<List<UserModel>> getAllStudents() async {
    final snap = await _db
        .collection(_usersCollection)
        .where('role', isEqualTo: 'student')
        .get();
    return snap.docs.map(_userFromDoc).toList();
  }

  /// Returns staff and student accounts (admin-only).
  Future<List<UserModel>> getManagedAccounts() async {
    if (await getCurrentRole() != UserRole.admin) {
      throw StateError('Only administrators can view managed accounts.');
    }
    final snap = await _db
        .collection(_usersCollection)
        .where('role', whereIn: ['staff', 'student'])
        .get();
    return snap.docs.map(_userFromDoc).toList();
  }

  /// Creates a staff or student Firebase Auth account + Firestore profile.
  ///
  /// [adminPassword] is required so the service can sign the admin back in
  /// after creating the new user (Firebase Auth replaces the current session
  /// when `createUserWithEmailAndPassword` is called).
  Future<AuthResult> createManagedAccount({
    required String username,
    required String password,
    required UserRole role,
    required String displayName,
    required String email,
    required String department,
    required String adminPassword,
    String? studentId,
    String? designation,
  }) async {
    final currentRole = await getCurrentRole();
    if (currentRole != UserRole.admin) {
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
    final normalizedDept = department.trim();
    final normalizedPw = password.trim();

    if (normalizedUsername.length < 3 ||
        normalizedPw.length < 6 ||
        normalizedName.isEmpty ||
        !normalizedEmail.contains('@') ||
        normalizedDept.isEmpty ||
        (role == UserRole.student &&
            (studentId?.trim().isNotEmpty != true)) ||
        (role == UserRole.staff &&
            (designation?.trim().isNotEmpty != true))) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'Please provide valid details for all required fields.',
      );
    }

    // Check for duplicate username in Firestore
    final usernameCheck = await _db
        .collection(_usersCollection)
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (usernameCheck.docs.isNotEmpty) {
      return const AuthResult(
        isSuccess: false,
        role: null,
        message: 'That username is already in use.',
      );
    }

    // Save admin identity before we lose the session
    final adminEmail = _auth.currentUser!.email!;

    try {
      // Create the new Firebase Auth user — this signs us out as admin
      final newCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPw,
      );

      final newUid = newCredential.user!.uid;

      // Update Firebase Auth display name for the new user
      await newCredential.user!.updateDisplayName(normalizedName);

      // Write profile to Firestore
      await _db.collection(_usersCollection).doc(newUid).set({
        'uid': newUid,
        'username': normalizedUsername,
        'role': _roleToString(role),
        'displayName': normalizedName,
        'email': normalizedEmail,
        'department': normalizedDept,
        if (role == UserRole.student) 'studentId': studentId?.trim(),
        if (role == UserRole.staff) 'designation': designation?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign admin back in to restore session
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final account = UserModel(
        uid: newUid,
        username: normalizedUsername,
        password: '',
        role: role,
        displayName: normalizedName,
        email: normalizedEmail,
        department: normalizedDept,
        studentId: role == UserRole.student ? studentId?.trim() : null,
        designation: role == UserRole.staff ? designation?.trim() : null,
      );

      return AuthResult(
        isSuccess: true,
        role: role,
        message: 'Account created successfully.',
        user: account,
      );
    } on FirebaseAuthException catch (e) {
      // If we failed mid-way, try to restore admin session
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } catch (_) {}

      final msg = switch (e.code) {
        'email-already-in-use' => 'That email address is already in use.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        'wrong-password' ||
        'invalid-credential' =>
          'Admin password incorrect. Session could not be restored.',
        _ => 'Could not create account: ${e.message ?? e.code}',
      };
      return AuthResult(isSuccess: false, role: null, message: msg);
    } catch (e) {
      // If we failed mid-way, try to restore admin session
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } catch (_) {}

      return AuthResult(
        isSuccess: false,
        role: null,
        message: 'Could not create account: $e',
      );
    }
  }

  /// Updates a user's profile fields in Firestore.
  Future<void> updateUserProfile(
    String uid,
    Map<String, String> updates,
  ) async {
    final updateData = <String, dynamic>{};
    if (updates.containsKey('name')) {
      updateData['displayName'] = updates['name'];
    }
    if (updates.containsKey('displayName')) {
      updateData['displayName'] = updates['displayName'];
    }
    if (updates.containsKey('department')) {
      updateData['department'] = updates['department'];
    }
    if (updates.containsKey('studentId')) {
      updateData['studentId'] = updates['studentId'];
    }
    if (updates.containsKey('designation')) {
      updateData['designation'] = updates['designation'];
    }
    if (updates.containsKey('year')) {
      updateData['year'] = updates['year'];
    }
    if (updates.containsKey('section')) {
      updateData['section'] = updates['section'];
    }
    if (updateData.isEmpty) return;

    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection(_usersCollection).doc(uid).set(
      updateData,
      SetOptions(merge: true),
    );

    // Also update Firebase Auth displayName if currentUser is the user being updated
    final newName = updateData['displayName'] as String?;
    if (newName != null && newName.isNotEmpty && _auth.currentUser?.uid == uid) {
      try {
        await _auth.currentUser!.updateDisplayName(newName);
      } catch (_) {}
    }

    // Sync studentName across all meetings created by this student
    if (newName != null && newName.isNotEmpty) {
      try {
        final meetingsSnap = await _db
            .collection('meetings')
            .where('studentUid', isEqualTo: uid)
            .get();
        if (meetingsSnap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in meetingsSnap.docs) {
            batch.update(doc.reference, {'studentName': newName});
          }
          await batch.commit();
        }
      } catch (_) {}
    }
  }

  /// Sends a password-reset email via Firebase Auth.
  ///
  /// Returns a user-friendly message. For security the message is kept
  /// intentionally vague so callers cannot enumerate valid emails.
  Future<String> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return 'Please enter a valid email address.';
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return 'If an account exists for $normalizedEmail, a password reset link has been sent.';
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ =>
          'If an account exists for $normalizedEmail, a password reset link has been sent.',
      };
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Signs out of Firebase Auth.
  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await PushNotificationService().unregisterUserDevice(uid);
      } catch (e) {
        debugPrint('⚠️ [FCM] Device unregister error on logout: $e');
      }
    }
    await _auth.signOut();
  }
}
