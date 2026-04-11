import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../assistants/cubits/assistant_cubit.dart';
import '../../../groups/cubits/group_cubit.dart';
import '../../../notes/cubits/notes_cubit.dart';
import '../../../students/cubits/student_cubit.dart';
import '../../cubits/report_cubit.dart';
enum NotesReportMode { all, student, group }

@RoutePage()
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType _selectedType = ReportType.student;
  int? _selectedStudentId;
  double? _minScore;
  double? _maxScore;
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedGroupId;
  int? _selectedAssistantId;
  int? _selectedNoteStudentId;
  int? _selectedNoteGroupId;
  NotesReportMode _notesReportMode = NotesReportMode.all;

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().loadStudents();
    context.read<GroupCubit>().loadGroups();
    context.read<AssistantCubit>().loadAssistants();
    context.read<NotesCubit>().loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state.isGenerated && state.pdfDocument != null) {
          // Show PDF preview
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: SizedBox(
                width: 800.w,
                height: 600.h,
                child: PdfPreview(
                  build: (format) => state.pdfDocument!.save(),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
              ),
            ),
          );
        }
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.reports.tr(),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          leading: ResponsiveLayout.isMobile(context)
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              : null,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.reports_subtitle.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24.h),

              // Report type selector
              Wrap(
                spacing: 8.w,
                runSpacing: 8.w,
                children: [
                  ChoiceChip(
                    label: Text(LocaleKeys.student_report.tr()),
                    selected: _selectedType == ReportType.student,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.student),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.highest_marks.tr()),
                    selected: _selectedType == ReportType.highestMarks,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.highestMarks),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.attendance_date.tr()),
                    selected: _selectedType == ReportType.attendanceDate,
                    onSelected: (_) => setState(
                      () => _selectedType = ReportType.attendanceDate,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.daily_payments.tr()),
                    selected: _selectedType == ReportType.dailyPayments,
                    onSelected: (_) => setState(
                      () => _selectedType = ReportType.dailyPayments,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.group_payments_report.tr()),
                    selected: _selectedType == ReportType.groupPayments,
                    onSelected: (_) => setState(
                      () => _selectedType = ReportType.groupPayments,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.assistant_report.tr()),
                    selected: _selectedType == ReportType.assistant,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.assistant),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.report_notes_delivery.tr()),
                    selected: _selectedType == ReportType.notesDelivery,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.notesDelivery),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: _selectedType == ReportType.student
                        ? _buildStudentReport(context)
                        : _selectedType == ReportType.highestMarks
                        ? _buildHighestMarksReport(context)
                        : _selectedType == ReportType.attendanceDate
                        ? _buildAttendanceDateReport(context)
                        : _selectedType == ReportType.dailyPayments
                        ? _buildDailyPaymentsReport(context)
                        : _selectedType == ReportType.groupPayments
                        ? _buildGroupPaymentsReport(context)
                        : _selectedType == ReportType.assistant
                        ? _buildAssistantReport(context)
                        : _buildNotesDeliveryReport(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.select_student.tr(), style: textTheme.titleMedium),
        SizedBox(height: 12.h),
        BlocBuilder<StudentCubit, StudentState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<int?>(
                  width: constraints.maxWidth,
                  initialSelection: _selectedStudentId,
                  label: Text(LocaleKeys.student.tr()),
                  leadingIcon: const Icon(Icons.person),
                  enableSearch: true,
                  enableFilter: true,
                  dropdownMenuEntries: state.students
                      .map(
                        (s) => DropdownMenuEntry<int?>(
                          value: s['id'] as int,
                          label: '${s['name']} (${s['serial_number']})',
                        ),
                      )
                      .toList(),
                  onSelected: (v) {
                    if (v != null) setState(() => _selectedStudentId = v);
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 24.h),
        BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _selectedStudentId == null || state.isLoading
                    ? null
                    : () => context.read<ReportCubit>().generateStudentReport(
                        _selectedStudentId!,
                      ),
                icon: state.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(LocaleKeys.generate_report.tr()),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceDateReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.attendance_date.tr(), style: textTheme.titleMedium),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.from_date.tr(),
                  prefixIcon: const Icon(Icons.date_range),
                ),
                controller: TextEditingController(
                  text: _fromDate != null
                      ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                      : '',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _fromDate = date);
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.to_date.tr(),
                  prefixIcon: const Icon(Icons.date_range),
                ),
                controller: TextEditingController(
                  text: _toDate != null
                      ? DateFormat('yyyy-MM-dd').format(_toDate!)
                      : '',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _toDate = date);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () =>
                          context.read<ReportCubit>().generateAttendanceReport(
                            fromDate: _fromDate,
                            toDate: _toDate,
                          ),
                icon: state.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(LocaleKeys.generate_report.tr()),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHighestMarksReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minController = TextEditingController(
      text: _minScore?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxScore?.toString() ?? '',
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.filter_score_range.tr(),
            style: textTheme.titleMedium,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.min_score.tr(),
                  ),
                  onChanged: (v) => _minScore = double.tryParse(v),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.max_score.tr(),
                  ),
                  onChanged: (v) => _maxScore = double.tryParse(v),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(LocaleKeys.filter_date_range.tr(), style: textTheme.titleMedium),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _fromDate?.toIso8601String().split('T').first ??
                        LocaleKeys.from_date.tr(),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _fromDate = d);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _toDate?.toIso8601String().split('T').first ??
                        LocaleKeys.to_date.tr(),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _toDate = d);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context
                            .read<ReportCubit>()
                            .generateHighestMarksReport(
                              minScore: _minScore,
                              maxScore: _maxScore,
                              fromDate: _fromDate,
                              toDate: _toDate,
                            ),
                  icon: state.isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(LocaleKeys.generate_report.tr()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPaymentsReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.select_day.tr(), style: textTheme.titleMedium),
        SizedBox(height: 12.h),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: LocaleKeys.paid_date.tr(),
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _fromDate != null
                ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                : '',
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _fromDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _fromDate = date);
          },
        ),
        SizedBox(height: 24.h),
        BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _fromDate == null || state.isLoading
                    ? null
                    : () => context
                          .read<ReportCubit>()
                          .generateDailyPaymentReport(_fromDate!),
                icon: state.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(LocaleKeys.generate_report.tr()),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupPaymentsReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.select_group.tr(), style: textTheme.titleMedium),
          SizedBox(height: 12.h),
          BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<int?>(
                    width: constraints.maxWidth,
                    initialSelection: _selectedGroupId,
                    label: Text(LocaleKeys.select_group.tr()),
                    leadingIcon: const Icon(Icons.groups),
                    enableSearch: true,
                    enableFilter: true,
                    dropdownMenuEntries: state.groups
                        .map(
                          (g) => DropdownMenuEntry<int?>(
                            value: g['id'] as int,
                            label: g['name'] as String,
                          ),
                        )
                        .toList(),
                    onSelected: (v) {
                      if (v != null) setState(() => _selectedGroupId = v);
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 16.h),
          Text(LocaleKeys.filter_date_range.tr(), style: textTheme.titleMedium),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _fromDate != null
                        ? DateFormat('MM/yyyy').format(_fromDate!)
                        : LocaleKeys.from_date.tr(),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _fromDate = d);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _toDate != null
                        ? DateFormat('MM/yyyy').format(_toDate!)
                        : LocaleKeys.to_date.tr(),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _toDate = d);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              final isReady =
                  _selectedGroupId != null &&
                  _fromDate != null &&
                  _toDate != null;
              return SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: !isReady || state.isLoading
                      ? null
                      : () {
                          final groupState = context.read<GroupCubit>().state;
                          final groupName =
                              groupState.groups.firstWhere(
                                    (g) => g['id'] == _selectedGroupId,
                                  )['name']
                                  as String;
                          context
                              .read<ReportCubit>()
                              .generateGroupPaymentsReport(
                                groupId: _selectedGroupId!,
                                groupName: groupName,
                                fromDate: _fromDate!,
                                toDate: _toDate!,
                              );
                        },
                  icon: state.isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(LocaleKeys.generate_report.tr()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.assistants.tr(), style: textTheme.titleMedium),
        SizedBox(height: 12.h),
        BlocBuilder<AssistantCubit, AssistantState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<int?>(
                  width: constraints.maxWidth,
                  initialSelection: _selectedAssistantId,
                  label: Text(LocaleKeys.assistants_directory.tr()),
                  leadingIcon: const Icon(Icons.support_agent),
                  enableSearch: true,
                  enableFilter: true,
                  dropdownMenuEntries: state.assistants
                      .map(
                        (a) => DropdownMenuEntry<int?>(
                          value: a['id'] as int,
                          label: '${a['name']} (${a['serial_number']})',
                        ),
                      )
                      .toList(),
                  onSelected: (v) {
                    if (v != null) setState(() => _selectedAssistantId = v);
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 24.h),
        BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            return SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _selectedAssistantId == null || state.isLoading
                    ? null
                    : () => context.read<ReportCubit>().generateAssistantReport(
                        _selectedAssistantId!,
                      ),
                icon: state.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(LocaleKeys.generate_report.tr()),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesDeliveryReport(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(LocaleKeys.report_notes_delivery.tr(), style: textTheme.titleMedium),
          SizedBox(height: 12.h),
          
          // Mode selector
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<NotesReportMode>(
                segments: [
                  ButtonSegment(
                    value: NotesReportMode.all,
                    label: Text(LocaleKeys.all_students.tr()),
                    icon: const Icon(Icons.people),
                  ),
                  ButtonSegment(
                    value: NotesReportMode.student,
                    label: Text(LocaleKeys.student.tr()),
                    icon: const Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: NotesReportMode.group,
                    label: Text(LocaleKeys.select_group.tr()),
                    icon: const Icon(Icons.groups),
                  ),
                ],
                selected: {_notesReportMode},
                onSelectionChanged: (value) {
                  setState(() {
                    _notesReportMode = value.first;
                    _selectedNoteStudentId = null;
                    _selectedNoteGroupId = null;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 24.h),

          if (_notesReportMode == NotesReportMode.student) ...[
            // Student selector
            BlocBuilder<StudentCubit, StudentState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<int?>(
                      width: constraints.maxWidth,
                      initialSelection: _selectedNoteStudentId,
                      label: Text(LocaleKeys.student.tr()),
                      leadingIcon: const Icon(Icons.person),
                      enableSearch: true,
                      enableFilter: true,
                      dropdownMenuEntries: [
                        ...state.students.map(
                          (s) => DropdownMenuEntry<int?>(
                            value: s['id'] as int,
                            label: '${s['name']} (${s['serial_number']})',
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        setState(() {
                          _selectedNoteStudentId = v;
                        });
                      },
                    );
                  },
                );
              },
            ),
            SizedBox(height: 16.h),
          ],

          if (_notesReportMode == NotesReportMode.group) ...[
            // Group selector
            BlocBuilder<GroupCubit, GroupState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<int?>(
                      width: constraints.maxWidth,
                      initialSelection: _selectedNoteGroupId,
                      label: Text(LocaleKeys.select_group.tr()),
                      leadingIcon: const Icon(Icons.groups),
                      enableSearch: true,
                      enableFilter: true,
                      dropdownMenuEntries: [
                        ...state.groups.map(
                          (g) => DropdownMenuEntry<int?>(
                            value: g['id'] as int,
                            label: g['name'] as String,
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        setState(() {
                          _selectedNoteGroupId = v;
                        });
                      },
                    );
                  },
                );
              },
            ),
            SizedBox(height: 16.h),
          ],

          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          String? groupName;
                          if (_selectedNoteGroupId != null) {
                            final groupState = context.read<GroupCubit>().state;
                            groupName = groupState.groups.firstWhere(
                                  (g) => g['id'] == _selectedNoteGroupId,
                                )['name'] as String;
                          }
                          context
                              .read<ReportCubit>()
                              .generateNotesDeliveryReport(
                                studentId: _selectedNoteStudentId,
                                groupId: _selectedNoteGroupId,
                                groupName: groupName,
                              );
                        },
                  icon: state.isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(LocaleKeys.generate_report.tr()),
                ),
              );
            },
          ),
        ],
    );
  }
}
