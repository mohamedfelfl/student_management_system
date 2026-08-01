import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/student_card_data.dart';
import 'qr_card_template_widget.dart';

class QrCardPreviewPanel extends StatefulWidget {
  final StudentCardData? student;
  final GlobalKey boundaryKey;
  final VoidCallback onExportSingle;
  final bool isExporting;

  const QrCardPreviewPanel({
    super.key,
    required this.student,
    required this.boundaryKey,
    required this.onExportSingle,
    this.isExporting = false,
  });

  @override
  State<QrCardPreviewPanel> createState() => _QrCardPreviewPanelState();
}

class _QrCardPreviewPanelState extends State<QrCardPreviewPanel> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.preview_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'معاينة البطاقة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (widget.student != null)
                FilledButton.icon(
                  onPressed: widget.isExporting ? null : widget.onExportSingle,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    'حفظ بطاقة الطالب',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Main Live Preview Display with Visible Horizontal Scrollbar
          Expanded(
            child: Center(
              child: widget.student == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'اختر طالباً من القائمة لعرض معاينة البطاقة',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RepaintBoundary(
                              key: widget.boundaryKey,
                              child: QrCardTemplateWidget(
                                student: widget.student!,
                                width: 600,
                                height: 350,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
