import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../attendance/cubits/attendance_cubit.dart';

class AttendanceTab extends StatelessWidget {
  final int studentId;
  const AttendanceTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.records.isEmpty) {
          return Center(child: Text(LocaleKeys.no_attendance_records.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.records.length,
          itemBuilder: (context, i) {
            final a = state.records[i];
            final status = a['status']?.toString() ?? '';
            Color chipColor;
            switch (status) {
              case 'attended':
                chipColor = Colors.green;
                break;
              case 'missed':
                chipColor = Colors.red;
                break;
              default:
                chipColor = Colors.orange;
            }

            final String statusLabel = status == 'attended' 
                ? LocaleKeys.attended.tr() 
                : status == 'missed' 
                    ? LocaleKeys.missed.tr() 
                    : status;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: chipColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a['date']?.toString() ?? '')),
                  Chip(
                    label: Text(statusLabel, style: TextStyle(color: chipColor, fontSize: 10.sp)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
