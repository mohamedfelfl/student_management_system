import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/qr_card_config.dart';
import '../../models/student_card_data.dart';

class QrCardControlBar extends StatelessWidget {
  final QRCardSelectionMode selectionMode;
  final ValueChanged<QRCardSelectionMode?> onSelectionModeChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Map<String, dynamic>> availableGroups;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupChanged;
  final List<String> availableStages;
  final String? selectedStage;
  final ValueChanged<String?> onStageChanged;

  const QrCardControlBar({
    super.key,
    required this.selectionMode,
    required this.onSelectionModeChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.availableGroups,
    required this.selectedGroupId,
    required this.onGroupChanged,
    required this.availableStages,
    required this.selectedStage,
    required this.onStageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Dropdown 1: Selection Mode
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<QRCardSelectionMode>(
              isExpanded: true,
              initialValue: selectionMode,
              decoration: InputDecoration(
                labelText: 'تحديد حسب',
                labelStyle: GoogleFonts.cairo(fontSize: 13),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: QRCardSelectionMode.student,
                  child: Text('طالب محدد'),
                ),
                DropdownMenuItem(
                  value: QRCardSelectionMode.group,
                  child: Text('مجموعة شعبة'),
                ),
                DropdownMenuItem(
                  value: QRCardSelectionMode.stage,
                  child: Text('المرحلة الدراسية'),
                ),
                DropdownMenuItem(
                  value: QRCardSelectionMode.all,
                  child: Text('جميع الطلاب'),
                ),
              ],
              onChanged: onSelectionModeChanged,
            ),
          ),

          // Secondary Dropdown for Group / Stage mode
          if (selectionMode == QRCardSelectionMode.group)
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'اختر المجموعة',
                  labelStyle: GoogleFonts.cairo(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('كل المجموعات'),
                  ),
                  ...availableGroups.map((g) {
                    final id = g['id'] as int;
                    final name = g['name'] as String? ?? '';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name),
                    );
                  }),
                ],
                onChanged: onGroupChanged,
              ),
            ),

          if (selectionMode == QRCardSelectionMode.stage)
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedStage,
                decoration: InputDecoration(
                  labelText: 'اختر المرحلة',
                  labelStyle: GoogleFonts.cairo(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('كل المراحل'),
                  ),
                  ...availableStages.map((stage) {
                    return DropdownMenuItem<String>(
                      value: stage,
                      child: Text(
                        StudentCardData.formatStageArabic(stage),
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                    );
                  }),
                ],
                onChanged: onStageChanged,
              ),
            ),

          // Search Field
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث باسم الطالب أو الكود...',
                hintStyle: GoogleFonts.cairo(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
