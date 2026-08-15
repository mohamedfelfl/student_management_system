import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/router/app_router.gr.dart';
import '../../../../app/constants/dimens.dart';
import '../../../../app/shared/animations/app_animations.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../cubits/attendance_cubit.dart';
import '../../models/attendance.dart';
import 'components/desktop_scanner_view.dart';
import 'components/mobile_scanner_view.dart';
import 'components/recent_scan_card.dart';

@RoutePage()
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _manualController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isDesktop = false;

  @override
  void initState() {
    super.initState();
    _isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (!_isDesktop) {
      _cameraController = MobileScannerController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AttendanceCubit>().loadRecentScans();
      }
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: context.router.canPop()
          ? AppBar(
              title: Text(
                LocaleKeys.qr_attendance.tr(),
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
            )
          : null,
      body: BlocListener<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state.scanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LocaleKeys.attendance_recorded_for.tr(
                    args: [state.lastScannedStudent ?? ''],
                  ),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _manualController.clear();
            context.read<AttendanceCubit>().resetScanState();
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<AttendanceCubit>().resetScanState();
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimens.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isDesktop)
                DesktopScannerView(manualController: _manualController)
              else
                MobileScannerView(
                  cameraController: _cameraController!,
                  manualController: _manualController,
                ),

              SizedBox(height: AppDimens.h32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.recent_record.tr(),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.router.push(AttendanceListRoute());
                    },
                    child: Text(LocaleKeys.view_all.tr()),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.h16),

              BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (context, state) {
                  if (state.records.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.r),
                        child: Text(
                          LocaleKeys.no_attendance_records.tr(),
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.records.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final record = state.records[index];
                      final String status =
                          record['status']?.toString() ?? '';
                      final bool isOwnGroup =
                          status == AttendanceStatus.attended.name;
                      final String notes =
                          record['notes']?.toString() ?? '';

                      final String displayStatus = notes.isNotEmpty
                          ? notes
                          : isOwnGroup
                          ? LocaleKeys.attended_his_group.tr()
                          : LocaleKeys.other_lesson.tr();

                      return RecentScanCard(
                        name: record['student_name'] as String? ?? 'Unknown',
                        time: record['date'] as String? ?? '',
                        status: displayStatus,
                        statusKey: status,
                      ).animateStaggeredEntrance(index: index);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color color;

  ScannerOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final length = 30.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
