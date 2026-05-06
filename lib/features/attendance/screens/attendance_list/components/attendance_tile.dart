import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../app/constants/dimens.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../models/attendance.dart';

/// A single attendance record tile with status badge and delete action.
class AttendanceTile extends StatelessWidget {
  final Map<String, Object?> record;
  final VoidCallback onDelete;

  const AttendanceTile({
    super.key,
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final String status =
        record['status']?.toString() ?? AttendanceStatus.attended.name;
    final String notes = record['notes']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.h12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.p16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['student_name']?.toString() ?? '',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppDimens.h4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: AppDimens.iconSize14,
                          color: textTheme.bodySmall?.color,
                        ),
                        SizedBox(width: AppDimens.w4),
                        Text(
                          record['date']?.toString() ?? '',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppDimens.w12),
              _buildBadge(status, notes, textTheme),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String status, String notes, TextTheme textTheme) {
    final String displayNotes = notes.isEmpty
        ? (status == AttendanceStatus.attended.name
            ? LocaleKeys.attended_his_group.tr()
            : status == AttendanceStatus.missed.name
                ? LocaleKeys.missed.tr()
                : LocaleKeys.other_lesson.tr())
        : notes;

    Color badgeColor;
    if (status == AttendanceStatus.attended.name) {
      badgeColor = Colors.green;
    } else if (status == AttendanceStatus.missed.name) {
      badgeColor = Colors.red;
    } else {
      badgeColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.w12,
        vertical: AppDimens.h6,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        displayNotes,
        style: textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
