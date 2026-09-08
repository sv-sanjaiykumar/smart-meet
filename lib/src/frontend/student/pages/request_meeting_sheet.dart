import 'package:flutter/material.dart';
import '../theme/student_theme.dart';

class RequestMeetingSheet extends StatefulWidget {
  const RequestMeetingSheet({super.key});

  @override
  State<RequestMeetingSheet> createState() => _RequestMeetingSheetState();
}

class _RequestMeetingSheetState extends State<RequestMeetingSheet> {
  String selectedDept = 'CSE';
  String? selectedPurpose = 'Project Discussion';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Date Selector
            Row(
              children: [
                Text(
                  '30th July',
                  style: TextStyle(
                    color: StudentColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_month_outlined, color: StudentColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Apply filters, pick faculty',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Department Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDeptChip('CSE', true),
                  _buildDeptChip('ECE', false),
                  _buildDeptChip('AI&ML', false),
                  _buildDeptChip('CSE-B', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Designation Dropdown
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Select faculty designation', style: TextStyle(fontSize: 14)),
                        isExpanded: true,
                        items: const [],
                        onChanged: (v) {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Optional*', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            // Purposes
            _buildPurposeGrid(),
            const SizedBox(height: 32),
            // Action Buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: StudentColors.primary.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_double_arrow_right, size: 18),
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
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? StudentColors.primary.withValues(alpha: 0.15) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? StudentColors.primary : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? StudentColors.primary : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          if (isSelected)
            const Icon(Icons.check, size: 14, color: StudentColors.primary)
          else
            Icon(Icons.circle, size: 6, color: Colors.grey[400]),
        ],
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
