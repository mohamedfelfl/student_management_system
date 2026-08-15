import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../../cubits/attendance_cubit.dart';
import '../qr_scanner_screen.dart';
import 'scanner_laser_beam.dart';

/// Mobile scanner view with camera, controls, and manual entry fallback.
class MobileScannerView extends StatelessWidget {
  final MobileScannerController cameraController;
  final TextEditingController manualController;

  const MobileScannerView({
    super.key,
    required this.cameraController,
    required this.manualController,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Camera Viewfinder Box
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                onDetect: (BarcodeCapture capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final Barcode barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      context.read<AttendanceCubit>().recordAttendanceBySerial(
                        barcode.rawValue!,
                      );
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
              // Animated Laser Beam
              Center(
                child: ScannerLaserBeam(
                  width: 200,
                  height: 200,
                  color: colorScheme.primary,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocaleKeys.active_now.tr(),
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
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
                onPressed: () => cameraController.toggleTorch(),
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(LocaleKeys.toggle_flash.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => cameraController.switchCamera(),
                icon: const Icon(Icons.cameraswitch_rounded),
                label: Text(LocaleKeys.switch_camera.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest,
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
          controller: manualController,
          decoration: InputDecoration(
            labelText: LocaleKeys.manual_entry.tr(),
            hintText: LocaleKeys.enter_serial_hint.tr(),
            prefixIcon: const Icon(Icons.keyboard),
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
      ],
    );
  }
}
