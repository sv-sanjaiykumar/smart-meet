import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/faculty_model.dart';

export 'models/faculty_model.dart';

/// Provides a faculty directory for the meeting-request sheet.
///
/// The list is seeded from [_defaultFaculty] on first launch and can be
/// updated dynamically (e.g., when a staff member edits their profile).
class FacultyService {
  static const String _key = 'smart_meet_faculty_directory';

  // ── Default faculty list ──────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _defaultFaculty = [
    // CSE
    {
      'id': 'fac_001',
      'name': 'Prof. Anushka Sharma',
      'department': 'CSE',
      'designation': 'Associate Professor',
      'specialization': 'Machine Learning',
      'email': 'anushka@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_002',
      'name': 'Dr. Ramesh Kumar',
      'department': 'CSE',
      'designation': 'Professor',
      'specialization': 'Database Systems',
      'email': 'ramesh@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_003',
      'name': 'Dr. Kavya Sree',
      'department': 'CSE',
      'designation': 'Assistant Professor',
      'specialization': 'Web Technologies',
      'email': 'kavya@college.edu',
      'isAvailable': true,
    },
    // ECE
    {
      'id': 'fac_004',
      'name': 'Prof. Anwar Raja',
      'department': 'ECE',
      'designation': 'Assistant Professor',
      'specialization': 'MicroControllers',
      'email': 'anwar@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_005',
      'name': 'Dr. Sunitha Devi',
      'department': 'ECE',
      'designation': 'Professor',
      'specialization': 'VLSI Design',
      'email': 'sunitha@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_006',
      'name': 'Mr. Vijay Kumar',
      'department': 'ECE',
      'designation': 'Assistant Professor',
      'specialization': 'Embedded Systems',
      'email': 'vijay@college.edu',
      'isAvailable': false,
    },
    // AI&ML
    {
      'id': 'fac_007',
      'name': 'Prof. Lakshmanan',
      'department': 'AI&ML',
      'designation': 'Professor',
      'specialization': 'Deep Learning',
      'email': 'lakshmanan@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_008',
      'name': 'Dr. Pooja Mehta',
      'department': 'AI&ML',
      'designation': 'Associate Professor',
      'specialization': 'Computer Vision',
      'email': 'pooja@college.edu',
      'isAvailable': true,
    },
    // CSE-B
    {
      'id': 'fac_009',
      'name': 'Dr. Alexa Maryam',
      'department': 'CSE-B',
      'designation': 'Assistant Professor',
      'specialization': 'Cloud Computing',
      'email': 'alexa@college.edu',
      'isAvailable': true,
    },
    {
      'id': 'fac_010',
      'name': 'Mr. Suresh Babu',
      'department': 'CSE-B',
      'designation': 'Lecturer',
      'specialization': 'Operating Systems',
      'email': 'suresh@college.edu',
      'isAvailable': true,
    },
  ];

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_key)) return;
    await prefs.setString(_key, jsonEncode(_defaultFaculty));
  }

  Future<List<FacultyModel>> _load() async {
    await _ensureSeeded();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FacultyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      await prefs.remove(_key);
      return _defaultFaculty
          .map((e) => FacultyModel.fromJson(e))
          .toList();
    }
  }

  Future<void> _save(List<FacultyModel> faculty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(faculty.map((f) => f.toJson()).toList()),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns all faculty members in the directory.
  Future<List<FacultyModel>> getAllFaculty() => _load();

  /// Returns faculty filtered by [department] (case-insensitive).
  Future<List<FacultyModel>> getFacultyByDepartment(String department) async {
    final all = await _load();
    return all
        .where((f) => f.department.toLowerCase() == department.toLowerCase())
        .toList();
  }

  /// Returns all departments that have at least one faculty member.
  Future<List<String>> getDepartments() async {
    final all = await _load();
    return all.map((f) => f.department).toSet().toList()..sort();
  }

  /// Searches faculty by name or department (case-insensitive substring match).
  Future<List<FacultyModel>> search(String query) async {
    if (query.trim().isEmpty) return _load();
    final all = await _load();
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

  /// Updates a faculty member's availability status.
  Future<void> setAvailability(String facultyId, {required bool isAvailable}) async {
    final all = await _load();
    final index = all.indexWhere((f) => f.id == facultyId);
    if (index == -1) return;
    final old = all[index];
    all[index] = FacultyModel(
      id: old.id,
      name: old.name,
      department: old.department,
      designation: old.designation,
      specialization: old.specialization,
      email: old.email,
      isAvailable: isAvailable,
    );
    await _save(all);
  }

  /// Updates a faculty member's profile fields (name, designation, specialization).
  /// Called when staff save their profile in [StaffProfilePage].
  Future<void> updateFacultyProfile(
    String facultyId, {
    String? name,
    String? designation,
    String? specialization,
  }) async {
    final all = await _load();
    final index = all.indexWhere((f) => f.id == facultyId);
    if (index == -1) return;
    final old = all[index];
    all[index] = FacultyModel(
      id: old.id,
      name: name ?? old.name,
      department: old.department,
      designation: designation ?? old.designation,
      specialization: specialization ?? old.specialization,
      email: old.email,
      isAvailable: old.isAvailable,
    );
    await _save(all);
  }
}
