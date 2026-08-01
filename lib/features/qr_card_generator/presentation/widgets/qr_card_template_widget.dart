import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/student_card_data.dart';

class QrCardTemplateWidget extends StatelessWidget {
  final StudentCardData student;
  final double width;
  final double height;

  const QrCardTemplateWidget({
    super.key,
    required this.student,
    this.width = 600,
    this.height = 350,
  });

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF071B38);
    const brandBlueColor = Color(0xFF1D61E7);
    const goldColor = Color(0xFFF3AB3C);
    const lightBgColor = Color(0xFFEBF3FF);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: navyColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Colors.white,
          child: Row(
            children: [
              // ── Left Branding Section (approx 33% width) ──
              Container(
                width: width * 0.33,
                height: double.infinity,
                color: lightBgColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Eagle Monitor Logo Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: navyColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.local_activity,
                            color: Colors.amber,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Brand Subtitle & Teacher Name
                    Column(
                      children: [
                        Text(
                          'The Legendary Eagle',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mr. Ali Sabry',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: brandBlueColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Golden ID Badge Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: goldColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'EAGLE MONITOR ID',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Line Divider
              Container(
                width: 2.5,
                height: double.infinity,
                color: const Color(0xFF00A8E8),
              ),

              // ── Right Main Student Info & QR Section (approx 67% width) ──
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    children: [
                      // Top Row: Student Data & QR Code
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Details (Arabic Text info)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  // Student Name
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      student.fullName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4, bottom: 12),
                                    width: 80,
                                    height: 1.5,
                                    color: Colors.black12,
                                  ),

                                  // Stage / Grade
                                  Text(
                                    StudentCardData.formatStageArabic(student.stageName),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: brandBlueColor,
                                    ),
                                  ),
                                  Text(
                                    'المرحلة',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Group / Schedule Details
                                  if (student.groupName.isNotEmpty ||
                                      student.groupSchedule.isNotEmpty) ...[
                                    Text(
                                      'المجموعة',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      student.groupName.isNotEmpty
                                          ? student.groupName
                                          : _formatScheduleArabic(student.groupSchedule),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Right Scannable QR Code Frame
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 135,
                                  height: 135,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: brandBlueColor,
                                      width: 2.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: QrImageView(
                                    data: student.qrPayload,
                                    version: QrVersions.auto,
                                    size: 120.0,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: navyColor,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: navyColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SCAN FOR ATTENDANCE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: brandBlueColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bottom Dark Navy Code Banner
                      Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          color: navyColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              student.studentCode,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'بطاقة تعريف الطالب',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
    );
  }

  String _formatScheduleArabic(String schedule) {
    switch (schedule.trim().toLowerCase()) {
      case 'saturday':
        return 'مجموعة السبت';
      case 'sunday':
        return 'مجموعة الأحد';
      case 'monday':
        return 'مجموعة الاثنين';
      case 'tuesday':
        return 'مجموعة الثلاثاء';
      case 'wednesday':
        return 'مجموعة الأربعاء';
      case 'thursday':
        return 'مجموعة الخميس';
      case 'friday':
        return 'مجموعة الجمعة';
      default:
        return schedule.isNotEmpty ? schedule : 'مجموعة عامة';
    }
  }
}
