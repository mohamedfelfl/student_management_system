import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:student_management_system/generated/locale_keys.g.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';
import 'package:student_management_system/features/students/services/student_merge_service.dart';

/// Modal dialog that allows selecting the primary student, displays
/// a clear breakdown/hint of how each piece of data is merged,
/// previews the exact transfer counts, and performs atomic merge.
class StudentMergeConfirmDialog extends StatefulWidget {
  final List<int> candidateStudentIds;
  final int? initialPrimaryId;

  const StudentMergeConfirmDialog({
    super.key,
    required this.candidateStudentIds,
    this.initialPrimaryId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<int> candidateStudentIds,
    int? initialPrimaryId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StudentMergeConfirmDialog(
        candidateStudentIds: candidateStudentIds,
        initialPrimaryId: initialPrimaryId,
      ),
    );
  }

  @override
  State<StudentMergeConfirmDialog> createState() =>
      _StudentMergeConfirmDialogState();
}

class _StudentMergeConfirmDialogState extends State<StudentMergeConfirmDialog> {
  int? _selectedPrimaryId;
  MergeSummary? _previewSummary;
  bool _isLoading = true;
  bool _isMerging = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPrimaryId = widget.initialPrimaryId ??
        (widget.candidateStudentIds.isNotEmpty
            ? widget.candidateStudentIds.first
            : null);
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (_selectedPrimaryId == null || widget.candidateStudentIds.length < 2) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'At least 2 students are required for merging.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cubit = context.read<StudentCubit>();
      final duplicateIds = widget.candidateStudentIds
          .where((id) => id != _selectedPrimaryId)
          .toList();

      final summary = await cubit.previewMerge(
        primaryId: _selectedPrimaryId!,
        duplicateIds: duplicateIds,
      );

      if (mounted) {
        setState(() {
          _previewSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPrimarySelected(int newPrimaryId) {
    if (_selectedPrimaryId == newPrimaryId) return;
    setState(() {
      _selectedPrimaryId = newPrimaryId;
    });
    _loadPreview();
  }

  Future<void> _performMerge() async {
    if (_selectedPrimaryId == null || _previewSummary == null) return;

    final summary = _previewSummary!;
    setState(() {
      _isMerging = true;
      _errorMessage = null;
    });

    try {
      final cubit = context.read<StudentCubit>();
      final duplicateIds = widget.candidateStudentIds
          .where((id) => id != _selectedPrimaryId)
          .toList();

      await cubit.mergeStudents(
        primaryId: _selectedPrimaryId!,
        duplicateIds: duplicateIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    LocaleKeys.students_merged_success.tr(
                      args: [
                        summary.primaryStudent.name,
                        '${summary.marksToTransfer}',
                        '${summary.attendanceToTransfer}',
                        '${summary.paymentsToTransfer}',
                      ],
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isMerging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720.w,
          maxHeight: 820.h,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.merge_type_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 26.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.merge_students.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          LocaleKeys.select_primary_desc.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isMerging ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                    tooltip: LocaleKeys.cancel.tr(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // ── Body ──
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: colorScheme.error,
                                    size: 40.r,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(color: colorScheme.error),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 12.h),
                                  OutlinedButton(
                                    onPressed: _loadPreview,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildDialogContent(theme, colorScheme),
              ),

              const Divider(height: 24),

              // ── Actions ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isMerging
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(LocaleKeys.cancel.tr()),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton.icon(
                    onPressed: (_isMerging || _isLoading || _previewSummary == null)
                        ? null
                        : _performMerge,
                    icon: _isMerging
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isMerging
                          ? LocaleKeys.loading.tr()
                          : LocaleKeys.confirm_merge.tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(ThemeData theme, ColorScheme colorScheme) {
    if (_previewSummary == null) return const SizedBox.shrink();

    final allCandidates = [
      _previewSummary!.primaryStudent,
      ..._previewSummary!.duplicateStudents,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Candidate Selection Cards ──
          Text(
            LocaleKeys.primary_student.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 8.h),
          ...allCandidates.map(
            (student) => _buildStudentSelectionCard(
              student: student,
              isSelectedPrimary: student.id == _selectedPrimaryId,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ),
          SizedBox(height: 16.h),

          // ── Data Flow Hint Box (Explicit User Requirement) ──
          _buildDataFlowHintBox(theme, colorScheme),
          SizedBox(height: 16.h),

          // ── Merge Breakdown & Conflict Preview ──
          _buildMergePreviewBreakdown(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStudentSelectionCard({
    required DuplicateStudent student,
    required bool isSelectedPrimary,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isSelectedPrimary
            ? colorScheme.primaryContainer.withAlpha(50)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelectedPrimary
              ? colorScheme.primary
              : colorScheme.outlineVariant.withAlpha(120),
          width: isSelectedPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isMerging ? null : () => _onPrimarySelected(student.id),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelectedPrimary
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelectedPrimary
                    ? Center(
                        child: Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelectedPrimary
                                ? colorScheme.primary
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isSelectedPrimary
                                ? LocaleKeys.primary_profile_badge.tr()
                                : LocaleKeys.duplicate_profile_badge.tr(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelectedPrimary
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 4.h,
                      children: [
                        _buildDetailChip(
                          icon: Icons.tag,
                          label: student.serialNumber,
                          colorScheme: colorScheme,
                        ),
                        if (student.groupName != null &&
                            student.groupName!.isNotEmpty)
                          _buildDetailChip(
                            icon: Icons.group_outlined,
                            label: student.groupName!,
                            colorScheme: colorScheme,
                          ),
                        if (student.phone1.isNotEmpty)
                          _buildDetailChip(
                            icon: Icons.phone_outlined,
                            label: student.phone1,
                            colorScheme: colorScheme,
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // Data stats pills
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        _buildStatBadge(
                          Icons.grade_outlined,
                          '${student.marksCount} ${LocaleKeys.exams.tr()}',
                          colorScheme.primary,
                        ),
                        _buildStatBadge(
                          Icons.how_to_reg_outlined,
                          '${student.attendanceCount} ${LocaleKeys.attendance.tr()}',
                          Colors.teal,
                        ),
                        _buildStatBadge(
                          Icons.receipt_long_outlined,
                          '${student.paymentsCount} ${LocaleKeys.payments.tr()}',
                          Colors.indigo,
                        ),
                        if (student.notesDeliveredCount > 0)
                          _buildStatBadge(
                            Icons.menu_book_outlined,
                            '${student.notesDeliveredCount} ${LocaleKeys.notes.tr()}',
                            Colors.orange.shade800,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.r, color: colorScheme.onSurfaceVariant),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withAlpha(60), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// The Data Flow Hint Box explains how data transfers and where it goes.
  Widget _buildDataFlowHintBox(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(150),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber.shade800,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                LocaleKeys.merge_data_flow_hint.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildHintItem(
            icon: Icons.grade_rounded,
            color: colorScheme.primary,
            text: LocaleKeys.merge_flow_marks.tr(),
          ),
          _buildHintItem(
            icon: Icons.fact_check_rounded,
            color: Colors.teal,
            text: LocaleKeys.merge_flow_attendance.tr(),
          ),
          _buildHintItem(
            icon: Icons.receipt_long_rounded,
            color: Colors.indigo,
            text: LocaleKeys.merge_flow_payments.tr(),
          ),
          _buildHintItem(
            icon: Icons.menu_book_rounded,
            color: Colors.orange.shade800,
            text: LocaleKeys.merge_flow_notes.tr(),
          ),
          _buildHintItem(
            icon: Icons.contact_phone_rounded,
            color: Colors.blue.shade700,
            text: LocaleKeys.merge_flow_profile.tr(),
          ),
          _buildHintItem(
            icon: Icons.delete_outline_rounded,
            color: colorScheme.error,
            text: LocaleKeys.merge_flow_removal.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.3,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the actual preview counts computed for the selected primary
  Widget _buildMergePreviewBreakdown(ThemeData theme, ColorScheme colorScheme) {
    final s = _previewSummary!;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: colorScheme.primary,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                LocaleKeys.data_merged_summary.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 6.h,
            children: [
              _buildSummaryRow(
                '${LocaleKeys.exams.tr()}:',
                '+${s.marksToTransfer}${s.marksConflictsResolved > 0 ? ' (${s.marksConflictsResolved} ${LocaleKeys.conflict_marks_notice.tr()})' : ''}',
              ),
              _buildSummaryRow(
                '${LocaleKeys.attendance.tr()}:',
                '+${s.attendanceToTransfer}${s.attendanceConflictsResolved > 0 ? ' (${s.attendanceConflictsResolved} combined)' : ''}',
              ),
              _buildSummaryRow(
                '${LocaleKeys.payments.tr()}:',
                '+${s.paymentsToTransfer}',
              ),
              if (s.notesToTransfer > 0 || s.notesConflictsResolved > 0)
                _buildSummaryRow(
                  '${LocaleKeys.notes.tr()}:',
                  '+${s.notesToTransfer}',
                ),
              if (s.profileFieldsUpdated.isNotEmpty)
                _buildSummaryRow(
                  'Profile Info Backfilled:',
                  s.profileFieldsUpdated.join(', '),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.blueGrey.shade800,
          ),
        ),
      ],
    );
  }
}
