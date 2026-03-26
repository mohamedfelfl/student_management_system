import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/router/app_router.gr.dart';
import '../../../../generated/locale_keys.g.dart';
import '../cubits/attendance_cubit.dart';
import '../models/attendance.dart';
import '../../../../app/shared/screens/shell_screen.dart';
import '../../../../app/shared/widgets/responsive_layout.dart';

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
    _isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (!_isDesktop) {
      _cameraController = MobileScannerController();
    }
    // Load recent scans when screen is opened
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => ShellScreen.scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Text('qr_attendance'.tr(), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: BlocListener<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state.scanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.attendance_recorded_for.tr(args: [state.lastScannedStudent ?? ''])),
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
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isDesktop)
                _buildDesktopScanner(context, isDark, colorScheme, textTheme)
              else
                _buildMobileScanner(context, isDark, colorScheme, textTheme),
                
              SizedBox(height: 32.h),
              
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('recent_record'.tr(), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                         context.router.push(AttendanceListRoute());
                      }, 
                      child: Text('view_all'.tr()),
                    ),
                  ],
                ),
              SizedBox(height: 16.h),
              
              BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (context, state) {
                  if (state.records.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.r),
                        child: Text(
                          'No recent records found.',
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.records.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final record = state.records[index];
                      final bool isSuccess = record['status'] == AttendanceStatus.attended.name;
                      
                      return _buildRecentScanCard(
                        name: record['student_name'] as String? ?? 'Unknown',
                        time: record['date'] as String? ?? '',
                        status: isSuccess ? LocaleKeys.attended.tr() : 'Another Group',
                        isDark: isDark,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        isSuccess: isSuccess,
                      );
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

  Widget _buildDesktopScanner(BuildContext context, bool isDark, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner_rounded, size: 80.r, color: colorScheme.primary),
          SizedBox(height: 24.h),
          Text(LocaleKeys.connect_scanner.tr(), style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(
            LocaleKeys.scanner_hint.tr(),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.student_serial_number.tr(),
                    hintText: LocaleKeys.scan_hint.tr(),
                    prefixIcon: const Icon(Icons.qr_code),
                    filled: true,
                    fillColor: isDark ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<AttendanceCubit>().recordAttendanceBySerial(value.trim());
                    }
                  },
                ),
              ),
              SizedBox(width: 16.w),
              ElevatedButton(
                onPressed: () {
                  final serial = _manualController.text.trim();
                  if (serial.isNotEmpty) {
                    context.read<AttendanceCubit>().recordAttendanceBySerial(serial);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20.r),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScanner(BuildContext context, bool isDark, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // Camera Viewfinder Box
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              MobileScanner(
                controller: _cameraController!,
                onDetect: (BarcodeCapture capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final Barcode barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      context.read<AttendanceCubit>().recordAttendanceBySerial(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              // Camera Overlay Design
              Center(
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: ScannerOverlayPainter(color: colorScheme.primary),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text('Active Now', style: textTheme.labelSmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Camera Controls
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _cameraController?.toggleTorch(),
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(LocaleKeys.toggle_flash.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _cameraController?.switchCamera(),
                icon: const Icon(Icons.cameraswitch_rounded),
                label: Text(LocaleKeys.switch_camera.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Manual Entry Fallback
        TextField(
          controller: _manualController,
          decoration: InputDecoration(
            labelText: LocaleKeys.manual_entry.tr(),
            hintText: LocaleKeys.enter_serial_hint.tr(),
            prefixIcon: const Icon(Icons.keyboard),
            filled: true,
            fillColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<AttendanceCubit>().recordAttendanceBySerial(value.trim());
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecentScanCard({
    required String name,
    required String time,
    required String status,
    required bool isDark,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isSuccess,
  }) {
    final Color statusColor = isSuccess ? const Color(0xFF6750A4) : const Color(0xFFB3261E);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: isSuccess ? Colors.green : Colors.orange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(time, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    
    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
    
    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
    
    // Scanning Line Animation placeholder
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(20, size.height / 2, size.width - 40, 2), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
