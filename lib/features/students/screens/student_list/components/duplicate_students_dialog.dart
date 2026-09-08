import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:student_management_system/generated/locale_keys.g.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';
import 'package:student_management_system/features/students/services/student_merge_service.dart';
import 'student_merge_confirm_dialog.dart';

/// Dialog that scans and displays all detected duplicate student clusters
/// and provides a direct path to review and merge each cluster.
class DuplicateStudentsDialog extends StatefulWidget {
  const DuplicateStudentsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const DuplicateStudentsDialog(),
    );
  }

  @override
  State<DuplicateStudentsDialog> createState() =>
      _DuplicateStudentsDialogState();
}

class _DuplicateStudentsDialogState extends State<DuplicateStudentsDialog> {
  final TextEditingController _filterController = TextEditingController();
  List<DuplicateStudentGroup> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _scanDuplicates();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _scanDuplicates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cubit = context.read<StudentCubit>();
      final groups = await cubit.findDuplicates();
      if (mounted) {
        setState(() {
          _groups = groups;
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

  List<DuplicateStudentGroup> get _filteredGroups {
    if (_filterQuery.trim().isEmpty) return _groups;
    final q = StudentMergeService.normalizeName(_filterQuery);
    return _groups.where((g) {
      if (g.key.contains(q) || g.displayName.contains(_filterQuery)) {
        return true;
      }
      return g.students.any((s) =>
          s.serialNumber.contains(_filterQuery) ||
          s.phone1.contains(_filterQuery) ||
          s.phone2.contains(_filterQuery));
    }).toList();
  }

  Future<void> _openMergeForGroup(DuplicateStudentGroup group) async {
    final candidateIds = group.students.map((s) => s.id).toList();
    final merged = await StudentMergeConfirmDialog.show(
      context,
      candidateStudentIds: candidateIds,
    );

    if (merged == true && mounted) {
      _scanDuplicates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredGroups;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860.w,
          maxHeight: 840.h,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
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
                      Icons.people_alt_outlined,
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
                          LocaleKeys.manage_duplicates.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _isLoading
                              ? LocaleKeys.loading.tr()
                              : LocaleKeys.duplicate_groups_count.tr(
                                  args: ['${_groups.length}'],
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _scanDuplicates,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: LocaleKeys.scan_duplicates.tr(),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: LocaleKeys.cancel.tr(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // ── Search / Filter Bar ──
              if (!_isLoading && _groups.isNotEmpty) ...[
                TextField(
                  controller: _filterController,
                  onChanged: (val) => setState(() => _filterQuery = val),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.search_hint.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _filterController.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // ── Body ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Scanning for duplicate student records...'),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
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
                                ),
                                SizedBox(height: 12.h),
                                OutlinedButton(
                                  onPressed: _scanDuplicates,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_outlined,
                                      size: 56.r,
                                      color: Colors.green.shade600,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      LocaleKeys.no_duplicates_found.tr(),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (ctx, idx) =>
                                    SizedBox(height: 14.h),
                                itemBuilder: (ctx, idx) {
                                  final group = filtered[idx];
                                  return _buildGroupCard(
                                    group: group,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                  );
                                },
                              ),
              ),

              const Divider(height: 24),

              // ── Close ──
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LocaleKeys.cancel.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required DuplicateStudentGroup group,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        group.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Text(
                          '${group.students.length} records',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMergeForGroup(group),
                  icon: const Icon(Icons.merge_type_rounded, size: 18),
                  label: Text(LocaleKeys.review_and_merge.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Students in group
            ...group.students.map(
              (student) => Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        student.serialNumber,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student.groupName != null &&
                        student.groupName!.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Text(
                        student.groupName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (student.phone1.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Text(
                        student.phone1,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(width: 12.w),
                    // Mini stat badges
                    _buildMiniBadge('${student.marksCount} 📝'),
                    SizedBox(width: 4.w),
                    _buildMiniBadge('${student.attendanceCount} 📅'),
                    SizedBox(width: 4.w),
                    _buildMiniBadge('${student.paymentsCount} 💳'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp),
      ),
    );
  }
}
