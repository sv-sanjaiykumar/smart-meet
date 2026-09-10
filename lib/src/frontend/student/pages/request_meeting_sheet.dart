import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../services/storage_service.dart';
import '../theme/student_theme.dart';

class RequestMeetingSheet extends StatefulWidget {
  const RequestMeetingSheet({super.key});

  @override
  State<RequestMeetingSheet> createState() => _RequestMeetingSheetState();
}

class _RequestMeetingSheetState extends State<RequestMeetingSheet> {
  String selectedDept = 'CSE';
  String? selectedPurpose = 'Project Discussion';
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storageService = StorageService();

  Future<void> _handleRequest() async {
    final meetings = await _storageService.getMeetings();
    
    // Create a new request based on UI selections
    final newMeeting = Meeting(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      facultyName: _searchController.text.isEmpty ? 'Prof. Alexa Maryam' : _searchController.text,
      facultyDept: 'Dept of $selectedDept',
      purpose: selectedPurpose ?? 'Academic doubts',
      status: MeetingStatus.pending,
      cardColorValue: 0xFFFFFFFF,
      requestedAt: DateFormat('dd MMM, h:mm a').format(DateTime.now()),
      isPinned: false,
    );

    meetings.insert(0, newMeeting); // Add to the top
    await _storageService.saveMeetings(meetings);
    
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate a new request was added
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meeting request sent successfully!'),
          backgroundColor: StudentColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
            const SizedBox(height: 30),
            // Date Selector
            Row(
              children: [
                Text(
                  '30th July',
                  style: TextStyle(
                    color: StudentColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.calendar_month_outlined, color: StudentColors.primary, size: 24),
              ],
            ),
            const SizedBox(height: 24),
            // Search Bar
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
                  hintText: 'Apply filters, pick faculty',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Department Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildDeptChip('CSE', selectedDept == 'CSE'),
                  _buildDeptChip('ECE', selectedDept == 'ECE'),
                  _buildDeptChip('AI&ML', selectedDept == 'AI&ML'),
                  _buildDeptChip('CSE-B', selectedDept == 'CSE-B'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Designation Dropdown
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Select faculty designation', style: TextStyle(fontSize: 15, color: Colors.grey)),
                        isExpanded: true,
                        items: const [],
                        onChanged: (v) {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Optional*', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 32),
            // Purposes Grid
            _buildPurposeGrid(),
            const SizedBox(height: 40),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text('Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      side: BorderSide(color: StudentColors.primary.withValues(alpha: 0.3)),
                      foregroundColor: StudentColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    onPressed: _handleRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildDeptChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedDept = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? StudentColors.primary.withValues(alpha: 0.1) : Colors.white,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildPurposeGrid() {
    final purposes = ['Academic', 'Project Discussion', 'Personal', 'Form Sign'];
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: purposes.map((p) => _buildPurposeItem(p)).toList(),
    );
  }

  Widget _buildPurposeItem(String label) {
    bool isSelected = selectedPurpose == label;
    return GestureDetector(
      onTap: () => setState(() => selectedPurpose = label),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2 - 40,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? StudentColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? StudentColors.ink : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
