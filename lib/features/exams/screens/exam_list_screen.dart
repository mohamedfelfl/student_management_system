import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/router/app_router.gr.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../../../generated/locale_keys.g.dart';
import '../cubits/exam_cubit.dart';
import '../models/student_exam_result.dart';

@RoutePage()
class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  int? _selectedExamId;
  int? _selectedGroupId;
  final Map<int, double> _studentMarks = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ExamCubit>().loadInitialData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.exams.tr(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    Scaffold.of(context).openDrawer(),
              )
            : const SizedBox.shrink(),
      ),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (BuildContext context, ExamState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final int totalExams = state.exams.length;

          return RefreshIndicator(
            onRefresh: () => context.read<ExamCubit>().loadExams(),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Purple Banner
                  Container(
                    padding: EdgeInsets.all(28.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 24.r,
                            offset: Offset(0, 8.h),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          LocaleKeys.exam_banner_title.tr(),
                          style: textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          LocaleKeys.exam_banner_subtitle.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () => context.router.push(ExamFormRoute()),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            LocaleKeys.add_exam.tr(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Mini Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerLow
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocaleKeys.scheduled_exams.tr(),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '$totalExams',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.description,
                                color: colorScheme.primary,
                                size: 28.r,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerLow
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocaleKeys.average_score.tr(),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${state.averageScore.toStringAsFixed(1)}%',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.bar_chart,
                                color: colorScheme.error,
                                size: 28.r,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerLow
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.search_hint.tr(),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Scheduled Exams List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_note, color: colorScheme.primary),
                          SizedBox(width: 8.w),
                          Text(
                            LocaleKeys.scheduled_exams.tr(),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            context.router.push(ExamsManagementRoute()),
                        child: Text(LocaleKeys.view_all.tr()),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (state.exams.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.r),
                        child: Text(
                          LocaleKeys.no_exams.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...state.exams
                        .where((e) {
                          final name =
                              e['name']?.toString().toLowerCase() ?? '';
                          final date =
                              e['date']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery) ||
                              date.contains(_searchQuery);
                        })
                        .map((e) {
                          final title = e['name']?.toString() ?? 'Exam';
                          final isMath = title.toLowerCase().contains('math');
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.h),
                            elevation: 0,
                            color: isDark
                                ? colorScheme.surfaceContainerLow
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              side: isDark
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 8.h,
                              ),
                              leading: Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  color: isMath
                                      ? const Color(0xFFD3BBFF)
                                      : const Color(0xFFFFD8E4),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  isMath ? Icons.functions : Icons.science,
                                  color: isMath
                                      ? const Color(0xFF4F378A)
                                      : const Color(0xFF633B48),
                                ),
                              ),
                              title: Text(
                                title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                LocaleKeys.total_mark.tr(
                                  args: [
                                    (e['full_mark'] as num?)?.toStringAsFixed(
                                          0,
                                        ) ??
                                        '0',
                                  ],
                                ),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  e['date']?.toString() ?? '',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => context.router.push(
                                ExamDetailRoute(examId: e['id'] as int),
                              ),
                            ),
                          );
                        }),
                  SizedBox(height: 32.h),

                  // Honor Board
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Color(0xFF8D6E63),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            LocaleKeys.honor_board.tr(),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.description_outlined),
                            onPressed: () {
                              _showExamFilterDialog(context, state.exams);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () async {
                              final DateTimeRange? picked =
                                  await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                              if (picked != null) {
                                if (context.mounted) {
                                  context.read<ExamCubit>().getTopStudents(
                                    startDate: picked.start,
                                    endDate: picked.end,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  state.topStudents.isEmpty
                      ? Center(child: Text(LocaleKeys.no_honor_students.tr()))
                      : SizedBox(
                          height: 180.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            itemCount: state.topStudents.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 12.w),
                            itemBuilder: (context, index) {
                              final student = state.topStudents[index];
                              return SizedBox(
                                width: 150.w,
                                child: _HonorCard(
                                  result: student,
                                  rank: index + 1,
                                  colorScheme: colorScheme,
                                  textTheme: textTheme,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                        ),
                  SizedBox(height: 32.h),

                  // Grade Entry Section
                  Row(
                    children: [
                      Icon(Icons.edit_document, color: colorScheme.primary),
                      SizedBox(width: 8.w),
                      Text(
                        LocaleKeys.grade_entry.tr(),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerLow
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16.r,
                            offset: Offset(0, 4.h),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          LocaleKeys.select_exam.tr(),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<int>(
                          initialValue:
                              state.exams.any((e) => e['id'] == _selectedExamId)
                              ? _selectedExamId
                              : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                          ),
                          items: state.exams
                              .map(
                                (exam) => DropdownMenuItem<int>(
                                  value: exam['id'] as int,
                                  child: Text(exam['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedExamId = val),
                          hint: Text(LocaleKeys.select_exam_hint.tr()),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          LocaleKeys.select_group.tr(),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<int>(
                          initialValue:
                              state.groups.any(
                                (g) => g['id'] == _selectedGroupId,
                              )
                              ? _selectedGroupId
                              : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                          ),
                          items: state.groups
                              .map(
                                (group) => DropdownMenuItem<int>(
                                  value: group['id'] as int,
                                  child: Text(group['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGroupId = val;
                              _studentMarks.clear();
                            });
                            if (val != null) {
                              context.read<ExamCubit>().loadGroupStudents(val);
                            }
                          },
                          hint: Text(LocaleKeys.select_group_hint.tr()),
                        ),
                        if (_selectedExamId != null &&
                            _selectedGroupId != null) ...[
                          SizedBox(height: 24.h),
                          Text(
                            LocaleKeys.students_marks.tr(),
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ...state.groupStudents.map((student) {
                            final studentId = student['id'] as int;
                            final exam = state.exams.firstWhere(
                              (e) => e['id'] == _selectedExamId,
                              orElse: () => {'full_mark': 100.0},
                            );
                            final fullMarkRaw = exam['full_mark'];
                            final fullMark = fullMarkRaw is num
                                ? fullMarkRaw.toDouble()
                                : double.tryParse(
                                        fullMarkRaw?.toString() ?? '100',
                                      ) ??
                                      100.0;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student['name'] as String,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  SizedBox(
                                    width: 70.w,
                                    child: TextField(
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.center,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText:
                                            '0 - ${fullMark.toStringAsFixed(0)}',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8.h,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? colorScheme
                                                  .surfaceContainerHighest
                                            : colorScheme.surfaceContainerLow,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final mark = double.tryParse(val);
                                        if (mark != null) {
                                          final cappedMark = mark > fullMark
                                              ? fullMark
                                              : mark;
                                          _studentMarks[studentId] = cappedMark;
                                        } else {
                                          _studentMarks.remove(studentId);
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    ' / ${fullMark.toStringAsFixed(0)}',
                                    style: textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: () {
                              if (_selectedExamId != null &&
                                  _studentMarks.isNotEmpty) {
                                context.read<ExamCubit>().saveMarks(
                                  _selectedExamId!,
                                  _studentMarks,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      LocaleKeys.marks_saved_success.tr(),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(LocaleKeys.save_marks.tr()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExamFilterDialog(BuildContext context, List<Map<String, dynamic>> exams) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          itemCount: exams.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: Text(LocaleKeys.view_all.tr()),
                onTap: () {
                  this.context.read<ExamCubit>().getTopStudents(); // Reset filter
                  Navigator.pop(bottomSheetContext);
                },
              );
            }
            final exam = exams[index - 1];
            return ListTile(
              leading: const Icon(Icons.description),
              title: Text(exam['name'] as String),
              subtitle: Text(exam['date']?.toString() ?? ''),
              onTap: () {
                this.context.read<ExamCubit>().getTopStudents(examId: exam['id'] as int);
                Navigator.pop(bottomSheetContext);
              },
            );
          },
        );
      },
    );
  }
}

class _HonorCard extends StatelessWidget {
  final StudentExamResult result;
  final int rank;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isDark;

  const _HonorCard({
    required this.result,
    required this.rank,
    required this.colorScheme,
    required this.textTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFF4F378A);
    } else if (rank == 2) {
      rankColor = const Color(0xFF79747E);
    } else {
      rankColor = const Color(0xFF8D6E63);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            result.studentName,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            '${result.totalMarks.toStringAsFixed(1)} / ${result.totalFullMarks.toStringAsFixed(0)}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${result.percentage.toStringAsFixed(1)}%',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
