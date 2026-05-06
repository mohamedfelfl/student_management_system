import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../app/constants/dimens.dart';
import '../../cubits/attendance_cubit.dart';
import 'components/attendance_tile.dart';

@RoutePage()
class AttendanceListScreen extends StatefulWidget {
  final int? studentId;

  const AttendanceListScreen({
    super.key,
    @QueryParam('studentId') this.studentId,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.studentId != null) {
        context.read<AttendanceCubit>().loadAttendance(widget.studentId!);
      } else {
        context.read<AttendanceCubit>().loadAllAttendance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.attendance_records.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDate == null
                  ? Icons.calendar_today
                  : Icons.calendar_today_outlined,
              color: _selectedDate == null ? null : colorScheme.primary,
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  LocaleKeys.filtering_by.tr(
                    args: [DateFormat('yyyy-MM-dd').format(_selectedDate!)],
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (BuildContext context, AttendanceState state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredRecords = _selectedDate == null
                      ? state.records
                      : state.records
                            .where(
                              (r) =>
                                  r['date'] ==
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!),
                            )
                            .toList();

                  if (filteredRecords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 64.r,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            LocaleKeys.no_attendance_records.tr(),
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredRecords.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Map<String, Object?> a = filteredRecords[i];
                      final int attendanceId = a['id'] as int;

                      return AttendanceTile(
                        record: a,
                        onDelete: () => _confirmDelete(context, attendanceId),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.delete_attendance_confirm.tr()),
        content: Text(LocaleKeys.delete_attendance_warning.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocaleKeys.delete.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.read<AttendanceCubit>().deleteAttendance(
      id,
      studentId: widget.studentId,
    );
  }
}
