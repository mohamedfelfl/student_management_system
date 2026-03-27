import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:student_management_system/generated/locale_keys.g.dart';

class PaymentStatsCard extends StatelessWidget {
  final double progress;

  const PaymentStatsCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final outlineColor = colorScheme.outlineVariant.withValues(alpha: 0.3);

    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: outlineColor),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160.r,
            height: 160.r,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 16.r,
                  valueColor: AlwaysStoppedAnimation(
                    colorScheme.surfaceContainerHigh,
                  ),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 16.r,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(
                    colorScheme.primary,
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: textTheme.displayMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            LocaleKeys.overall_payment_status.tr(),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            progress >= 1.0
                ? LocaleKeys.payment_success_msg.tr()
                : LocaleKeys.payment_ontrack_msg.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
