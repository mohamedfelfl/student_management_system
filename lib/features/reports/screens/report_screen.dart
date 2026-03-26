import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../app/shared/widgets/responsive_layout.dart';

import '../cubits/report_cubit.dart';
import '../../students/cubits/student_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().loadStudents();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.reports.tr(), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 24.h),
  
              // Report type selector
              Wrap(
                spacing: 8.w,
                children: [
                  ChoiceChip(
                    label: Text(LocaleKeys.student_report.tr()),
                    selected: _selectedType == ReportType.student,
                    onSelected: (_) => setState(() => _selectedType = ReportType.student),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.highest_marks.tr()),
                    selected: _selectedType == ReportType.highestMarks,
                    onSelected: (_) => setState(() => _selectedType = ReportType.highestMarks),
                  ),
                  ChoiceChip(
                    label: Text(LocaleKeys.attendance_date.tr()),
                    selected: _selectedType == ReportType.attendanceDate,
                    onSelected: (_) => setState(() => _selectedType = ReportType.attendanceDate),
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
                            : _buildAttendanceDateReport(context),
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
                      .map((s) => DropdownMenuEntry<int?>(
                            value: s['id'] as int,
                            label: '${s['name']} (${s['serial_number']})',
                          ))
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
                    : () => context
                        .read<ReportCubit>()
                        .generateStudentReport(_selectedStudentId!),
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
                  text: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : '',
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
                  text: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : '',
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
                    : () => context.read<ReportCubit>().generateAttendanceReport(
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
    final minController = TextEditingController(text: _minScore?.toString() ?? '');
    final maxController = TextEditingController(text: _maxScore?.toString() ?? '');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.filter_score_range.tr(), style: textTheme.titleMedium),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: LocaleKeys.min_score.tr()),
                  onChanged: (v) => _minScore = double.tryParse(v),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: LocaleKeys.max_score.tr()),
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
                  title: Text(_fromDate?.toIso8601String().split('T').first ?? LocaleKeys.from_date.tr()),
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
                  title: Text(_toDate?.toIso8601String().split('T').first ?? LocaleKeys.to_date.tr()),
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
                      : () => context.read<ReportCubit>().generateHighestMarksReport(
                            minScore: _minScore,
                            maxScore: _maxScore,
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
      ),
    );
  }
}
