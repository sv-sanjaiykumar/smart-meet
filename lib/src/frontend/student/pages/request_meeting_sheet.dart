import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/faculty_service.dart';
import '../../../backend/meeting_service.dart';
import '../theme/student_theme.dart';

class RequestMeetingSheet extends StatefulWidget {
  const RequestMeetingSheet({super.key});

  @override
  State<RequestMeetingSheet> createState() => _RequestMeetingSheetState();
}

class _RequestMeetingSheetState extends State<RequestMeetingSheet> {
  // ── services ───────────────────────────────────────────────────────────────
  final FacultyService _facultyService = FacultyService();
  final MeetingService _meetingService = MeetingService();

  // ── state ──────────────────────────────────────────────────────────────────
  String _selectedDept = 'CSE';
  String? _selectedPurpose = 'Project Discussion';
  String? _selectedDesignation;
  FacultyModel? _selectedFaculty;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final TextEditingController _searchController = TextEditingController();

  List<FacultyModel> _allFaculty = [];
  List<FacultyModel> _filtered = [];
  List<String> _departments = [];
  bool _loadingFaculty = true;

  static const List<String> _purposes = [
    'Academic',
    'Project Discussion',
    'Personal',
    'Form Sign',
    'Exam Clarification',
    'Research Query',
  ];

  static const List<String> _designations = [
    'Professor',
    'Associate Professor',
    'Assistant Professor',
    'Lecturer',
  ];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFaculty();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadFaculty() async {
    final faculty = await _facultyService.getAllFaculty();
    final depts = await _facultyService.getDepartments();
    if (!mounted) return;
    setState(() {
      _allFaculty = faculty;
      _departments = depts;
      _loadingFaculty = false;
      if (_departments.isNotEmpty && !_departments.contains(_selectedDept) && _selectedDept != 'All') {
        _selectedDept = _departments.first;
      }
      _applyFilters();
    });
  }

  void _onSearchChanged() => setState(_applyFilters);

  bool _matchesDesignation(String actual, String filter) {
    final a = actual.toLowerCase().trim();
    final f = filter.toLowerCase().trim();
    if (a == f) return true;
    if ((a == 'ap' || a == 'assistant professor' || a == 'asst prof' || a == 'asst. prof') &&
        (f == 'ap' || f == 'assistant professor' || f == 'asst prof' || f == 'asst. prof')) {
      return true;
    }
    if ((a == 'asp' || a == 'associate professor' || a == 'assoc prof' || a == 'assoc. prof') &&
        (f == 'asp' || f == 'associate professor' || f == 'assoc prof' || f == 'assoc. prof')) {
      return true;
    }
    if ((a == 'prof' || a == 'professor') && (f == 'prof' || f == 'professor')) {
      return true;
    }
    return false;
  }

  void _applyFilters() {
    var list = _allFaculty;
    if (_selectedDept != 'All') {
      list = list
          .where((f) => f.department.toLowerCase() == _selectedDept.toLowerCase())
          .toList();
    }

    if (_selectedDesignation != null) {
      list = list
          .where((f) => _matchesDesignation(f.designation, _selectedDesignation!))
          .toList();
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                (f.specialization?.toLowerCase().contains(q) ?? false) ||
                f.designation.toLowerCase().contains(q) ||
                f.department.toLowerCase().contains(q),
          )
          .toList();
    }

    _filtered = list;

    // De-select faculty if they no longer appear in the filtered list
    if (_selectedFaculty != null &&
        !_filtered.any((f) => f.id == _selectedFaculty!.id)) {
      _selectedFaculty = null;
    }
  }

  // ── submission ─────────────────────────────────────────────────────────────

  Future<void> _handleRequest() async {
    if (_selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting purpose.')),
      );
      return;
    }

    final facultyName = _selectedFaculty?.name ??
        (_searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : 'Faculty');
    final facultyDept = 'Dept of $_selectedDept';

    setState(() => _isSubmitting = true);

    try {
      await _meetingService.submitMeetingRequest(
        facultyName: facultyName,
        facultyDept: facultyDept,
        purpose: _selectedPurpose!,
        facultyUid: _selectedFaculty?.id,
        facultyEmail: _selectedFaculty?.email,
        meetingDate: _selectedDate,
        // Use the matching staff username if available
        staffUsername: _staffUsernameFor(facultyName),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meeting request sent successfully!'),
          backgroundColor: StudentColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Best-effort mapping from faculty display name or email to a staff username.
  String _staffUsernameFor(String facultyName) {
    if (_selectedFaculty?.email != null &&
        _selectedFaculty!.email!.contains('@')) {
      return _selectedFaculty!.email!.split('@').first;
    }
    final lower = facultyName.toLowerCase();
    if (lower.contains('kumar')) return 'kumar.staff';
    if (lower.contains('anushka')) return 'anushka';
    if (lower.contains('lakshmanan')) return 'lakshmanan';
    if (lower.contains('anwar')) return 'staff';
    return 'staff';
  }

  // ── date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Date selector ────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: Row(
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      color: StudentColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.calendar_month_outlined,
                      color: StudentColors.primary, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Faculty search ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search faculty by name or specialization',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Department chips ─────────────────────────────────────────────
            if (_departments.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    if (_departments.length > 1)
                      _buildDeptChip('All', _selectedDept == 'All'),
                    ..._departments
                        .map((d) => _buildDeptChip(d, _selectedDept == d)),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: ['CSE', 'ECE', 'AI&ML', 'CSE-B']
                      .map((d) => _buildDeptChip(d, _selectedDept == d))
                      .toList(),
                ),
              ),
            const SizedBox(height: 20),

            // ── Designation filter ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text(
                          'Filter by designation',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        value: _selectedDesignation,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All designations'),
                          ),
                          ..._designations.map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() {
                              _selectedDesignation = v;
                              _applyFilters();
                            }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Optional*',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Faculty list ─────────────────────────────────────────────────
            if (_loadingFaculty)
              const Center(child: CircularProgressIndicator())
            else if (_filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No faculty found for the selected filters.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select faculty (${_filtered.length})',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._filtered.map(_buildFacultyCard),
                ],
              ),
            const SizedBox(height: 24),

            // ── Purpose grid ─────────────────────────────────────────────────
            _buildPurposeGrid(),
            const SizedBox(height: 36),

            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () {},
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text(
                      'Preview',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: BorderSide(
                        color: StudentColors.primary.withValues(alpha: 0.3),
                      ),
                      foregroundColor: StudentColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Request',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.keyboard_double_arrow_right, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── widget builders ────────────────────────────────────────────────────────

  Widget _buildDeptChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDept = label;
        _selectedFaculty = null;
        _applyFilters();
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? StudentColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? StudentColors.primary : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? StudentColors.primary : Colors.grey[600],
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: StudentColors.primary)
            else
              Icon(Icons.circle, size: 6, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard(FacultyModel faculty) {
    final isSelected = _selectedFaculty?.id == faculty.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFaculty = isSelected ? null : faculty;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? StudentColors.primary.withValues(alpha: 0.06)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? StudentColors.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? StudentColors.primary.withValues(alpha: 0.15)
                  : Colors.grey[200],
              child: Text(
                _getInitial(faculty.name),
                style: TextStyle(
                  color: isSelected ? StudentColors.primary : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculty.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? StudentColors.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    faculty.specialization != null &&
                            faculty.specialization!.isNotEmpty
                        ? '${_formatDesignation(faculty.designation)} · ${faculty.specialization}'
                        : '${_formatDesignation(faculty.designation)} · ${faculty.department}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!faculty.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'Busy',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: StudentColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purpose of visit',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 14,
              children: _purposes
                  .map(
                    (label) => SizedBox(
                      width: itemWidth,
                      child: _buildPurposeItem(label),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurposeItem(String label) {
    final isSelected = _selectedPurpose == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedPurpose = label),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? StudentColors.primary : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? StudentColors.ink : Colors.grey[600],
                fontWeight:
                    isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = switch (day % 10) {
      1 when day != 11 => 'st',
      2 when day != 12 => 'nd',
      3 when day != 13 => 'rd',
      _ => 'th',
    };
    return '${DateFormat('MMMM').format(date)} $day$suffix';
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'F';
    return trimmed[0].toUpperCase();
  }

  String _formatDesignation(String d) {
    final lower = d.toLowerCase().trim();
    if (lower == 'ap') return 'Assistant Professor';
    if (lower == 'asp') return 'Associate Professor';
    if (lower == 'prof') return 'Professor';
    return d;
  }
}
