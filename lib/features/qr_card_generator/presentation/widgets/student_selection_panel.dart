import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/student_card_data.dart';

class StudentSelectionPanel extends StatelessWidget {
  final List<StudentCardData> students;
  final Set<int> selectedStudentIds;
  final StudentCardData? activePreviewStudent;
  final ValueChanged<StudentCardData> onStudentSelectedForPreview;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<bool?> onToggleSelectAll;
  final VoidCallback onBatchExport;

  const StudentSelectionPanel({
    super.key,
    required this.students,
    required this.selectedStudentIds,
    required this.activePreviewStudent,
    required this.onStudentSelectedForPreview,
    required this.onToggleSelection,
    required this.onToggleSelectAll,
    required this.onBatchExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAllSelected =
        students.isNotEmpty && selectedStudentIds.length == students.length;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Header Bar with Select All & Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: onToggleSelectAll,
                    ),
                    Text(
                      'تحديد الكل (${students.length})',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (selectedStudentIds.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          '${selectedStudentIds.length} محدد',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        backgroundColor: colorScheme.primaryContainer,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: selectedStudentIds.isEmpty ? null : onBatchExport,
                  icon: const Icon(Icons.drive_folder_upload_rounded, size: 18),
                  label: Text(
                    'تصدير المحدد كـ PNG',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Student List
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد طلاب متاحون بحسب خيارات التصفية',
                      style: GoogleFonts.cairo(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: students.length,
                    separatorBuilder: (ctx, idx) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isSelected = selectedStudentIds.contains(student.id);
                      final isPreviewed =
                          activePreviewStudent?.id == student.id;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          selected: isPreviewed,
                          selectedTileColor:
                              colorScheme.primaryContainer.withValues(alpha: 0.3),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) => onToggleSelection(student.id),
                          ),
                          title: Text(
                            student.fullName,
                            style: GoogleFonts.cairo(
                              fontWeight: isPreviewed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${student.studentCode} • ${student.stageName} ${student.groupName.isNotEmpty ? '• ${student.groupName}' : ''}',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.remove_red_eye_outlined,
                              color: isPreviewed
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () =>
                                onStudentSelectedForPreview(student),
                            tooltip: 'معاينة بطاقة الطالب',
                          ),
                          onTap: () => onStudentSelectedForPreview(student),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
