import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/faculty_model.dart';

export 'models/faculty_model.dart';

/// Provides a faculty directory fetched directly from Firebase Firestore.
///
/// Faculty accounts are loaded from the 'users' collection where role == 'staff'.
/// Legacy local storage mocks are purged automatically.
class FacultyService {
  FacultyService({FirebaseFirestore? db}) : _injectedDb = db {
    _cleanLegacyLocalStorage();
  }

  final FirebaseFirestore? _injectedDb;

  FirebaseFirestore? get _db {
    if (_injectedDb != null) return _injectedDb;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static void _cleanLegacyLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('smart_meet_faculty_directory')) {
        await prefs.remove('smart_meet_faculty_directory');
      }
    } catch (_) {}
  }

  /// Returns all faculty members directly from Firestore 'users' collection.
  Future<List<FacultyModel>> getAllFaculty() async {
    final db = _db;
    if (db == null) return [];

    try {
      final snap = await db
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();

      final list = snap.docs.map((doc) {
        final data = doc.data();
        final rawName = data['displayName'] as String? ??
            data['username'] as String? ??
            'Faculty';
        final rawDept = data['department'] as String? ?? 'CSE';
        final rawDesignation = data['designation'] as String? ?? 'Professor';
        final rawSpec = data['specialization'] as String?;
        final rawEmail = data['email'] as String? ?? '';
        final isAvailable = data['isAvailable'] as bool? ?? true;

        return FacultyModel(
          id: doc.id,
          name: rawName,
          department: rawDept,
          designation: rawDesignation,
          specialization: rawSpec,
          email: rawEmail,
          isAvailable: isAvailable,
        );
      }).toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching faculty from Firestore: $e');
      return [];
    }
  }

  /// Returns faculty filtered by [department] (case-insensitive).
  Future<List<FacultyModel>> getFacultyByDepartment(String department) async {
    final all = await getAllFaculty();
    if (department.toLowerCase() == 'all') return all;
    return all
        .where((f) => f.department.toLowerCase() == department.toLowerCase())
        .toList();
  }

  /// Returns all distinct departments that have at least one faculty member.
  Future<List<String>> getDepartments() async {
    final all = await getAllFaculty();
    final depts = all
        .map((f) => f.department.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return depts;
  }

  /// Searches faculty by name, department, designation, or specialization.
  Future<List<FacultyModel>> search(String query) async {
    final all = await getAllFaculty();
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.department.toLowerCase().contains(q) ||
              f.designation.toLowerCase().contains(q) ||
              (f.specialization?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  /// Updates a faculty member's availability status in Firestore.
  Future<void> setAvailability(String facultyId, {required bool isAvailable}) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(facultyId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      debugPrint('❌ Error updating availability in Firestore: $e');
    }
  }

  /// Updates a faculty member's profile fields in Firestore.
  Future<void> updateFacultyProfile(
    String facultyId, {
    String? name,
    String? designation,
    String? specialization,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['displayName'] = name.trim();
      }
      if (designation != null && designation.trim().isNotEmpty) {
        updates['designation'] = designation.trim();
      }
      if (specialization != null) {
        updates['specialization'] = specialization.trim();
      }
      if (updates.isNotEmpty) {
        await db.collection('users').doc(facultyId).update(updates);
      }
    } catch (e) {
      debugPrint('❌ Error updating faculty profile in Firestore: $e');
    }
  }
}
