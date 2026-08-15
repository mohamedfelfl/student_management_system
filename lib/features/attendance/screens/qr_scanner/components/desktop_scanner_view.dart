import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/constants/dimens.dart';
import '../../../../../app/shared/animations/app_animations.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../cubits/attendance_cubit.dart';

/// Desktop scanner view with manual serial number entry field.
class DesktopScannerView extends StatelessWidget {
  final TextEditingController manualController;

  const DesktopScannerView({
    super.key,
    required this.manualController,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppDimens.p32),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimens.r32),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 80,
            color: colorScheme.primary,
          ).animatePulseHighlight(),
          SizedBox(height: AppDimens.h24),
          Text(
            LocaleKeys.connect_scanner.tr(),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppDimens.h8),
          Text(
            LocaleKeys.scanner_hint.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.h32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: manualController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.student_serial_number.tr(),
                    hintText: LocaleKeys.scan_hint.tr(),
                    prefixIcon: const Icon(Icons.qr_code),
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surfaceContainerLow
                        : colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<AttendanceCubit>().recordAttendanceBySerial(
                        value.trim(),
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: AppDimens.w16),
              ElevatedButton(
                onPressed: () {
                  final serial = manualController.text.trim();
                  if (serial.isNotEmpty) {
                    context.read<AttendanceCubit>().recordAttendanceBySerial(
                      serial,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(AppDimens.p20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.r16),
                  ),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    ).animateSpringEntrance();
  }
}
