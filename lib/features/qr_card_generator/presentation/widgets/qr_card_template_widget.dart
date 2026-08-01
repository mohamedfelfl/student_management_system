import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/constants/dimens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/student_card_data.dart';

class QrCardTemplateWidget extends StatelessWidget {
  final StudentCardData student;
  final double? width;
  final double? height;

  const QrCardTemplateWidget({
    super.key,
    required this.student,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = width ?? AppDimens.cardDefaultWidth;
    final cardH = height ?? AppDimens.cardDefaultHeight;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: cardW,
        height: cardH,
        decoration: BoxDecoration(
          color: AppCardColors.navy,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 12.0,
              offset: Offset(0, 6.0),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            color: AppCardColors.cardWhite,
            child: Row(
              children: [
                // Left Branding Section (198px wide)
                Container(
                  width: cardW * 0.33,
                  height: double.infinity,
                  color: AppCardColors.lightBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 14.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 90.0,
                        height: 90.0,
                        decoration: BoxDecoration(
                          color: AppCardColors.navy,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6.0,
                              offset: Offset(0, 3.0),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.0),
                          child: Image.asset(
                            AppConstants.logoAssetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.local_activity,
                              color: AppCardColors.iconAmber,
                              size: 48.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6.0),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'The Legendary Eagle',
                              style: AppTypography.outfit(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w800,
                                color: AppCardColors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ali Sabry',
                              style: AppTypography.outfit(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w900,
                                color: AppCardColors.brandBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: AppCardColors.gold,
                          borderRadius: BorderRadius.circular(18.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 4.0,
                              offset: Offset(0, 2.0),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'EAGLE MONITOR ID',
                            textAlign: TextAlign.center,
                            style: AppTypography.outfit(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w900,
                              color: AppCardColors.textDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider Line
                Container(
                  width: 2.5,
                  height: double.infinity,
                  color: AppCardColors.cyanDivider,
                ),

                // Right Main Student Info & QR Section
                Expanded(
                  child: Container(
                    color: AppCardColors.cardWhite,
                    padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 10.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side: Student Name (at top), Stage & Group info (centered vertically)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 4.0),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        student.fullName,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.cairo(
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.w900,
                                          color: AppCardColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(
                                        top: 4.0,
                                        bottom: 4.0,
                                      ),
                                      width: 80.0,
                                      height: 1.5,
                                      color: const Color(0x1A000000),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                StudentCardData.formatStageArabic(
                                                  student.stageName,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: AppTypography.cairo(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AppCardColors.brandBlue,
                                                ),
                                              ),
                                              Text(
                                                'المرحلة الدراسية',
                                                textAlign: TextAlign.center,
                                                style: AppTypography.cairo(
                                                  fontSize: 11.0,
                                                  color:
                                                      AppCardColors.textMuted,
                                                ),
                                              ),
                                              if (student
                                                      .groupName
                                                      .isNotEmpty ||
                                                  student
                                                      .groupSchedule
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 6.0),
                                                Text(
                                                  'المجموعة',
                                                  textAlign: TextAlign.center,
                                                  style: AppTypography.cairo(
                                                    fontSize: 11.0,
                                                    color:
                                                        AppCardColors.textMuted,
                                                  ),
                                                ),
                                                Text(
                                                  student.groupName.isNotEmpty
                                                      ? student.groupName
                                                      : _formatScheduleArabic(
                                                          student.groupSchedule,
                                                        ),
                                                  textAlign: TextAlign.center,
                                                  style: AppTypography.cairo(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppCardColors.textDark,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8.0),

                              // Right side: QR Code Box
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 125.0,
                                    height: 125.0,
                                    decoration: BoxDecoration(
                                      color: AppCardColors.cardWhite,
                                      borderRadius: BorderRadius.circular(14.0),
                                      border: Border.all(
                                        color: AppCardColors.brandBlue,
                                        width: 2.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4.0),
                                    child: QrImageView(
                                      data: student.qrPayload,
                                      version: QrVersions.auto,
                                      size: 115.0,
                                      backgroundColor: AppCardColors.cardWhite,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppCardColors.navy,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: AppCardColors.navy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'SCAN FOR ATTENDANCE',
                                      style: AppTypography.outfit(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w900,
                                        color: AppCardColors.brandBlue,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6.0),

                        // Bottom Banner
                        Container(
                          width: double.infinity,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: AppCardColors.navy,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'STUDENT ID',
                                  style: AppTypography.cairo(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppCardColors.cardWhite,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    student.studentCode,
                                    style: AppTypography.outfit(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w900,
                                      color: AppCardColors.cardWhite,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatScheduleArabic(String schedule) {
    switch (schedule.trim().toLowerCase()) {
      case AppConstants.daySaturday:
        return 'مجموعة السبت';
      case AppConstants.daySunday:
        return 'مجموعة الأحد';
      case AppConstants.dayMonday:
        return 'مجموعة الاثنين';
      case AppConstants.dayTuesday:
        return 'مجموعة الثلاثاء';
      case AppConstants.dayWednesday:
        return 'مجموعة الأربعاء';
      case AppConstants.dayThursday:
        return 'مجموعة الخميس';
      case AppConstants.dayFriday:
        return 'مجموعة الجمعة';
      default:
        return schedule.isNotEmpty ? schedule : 'مجموعة عامة';
    }
  }
}
