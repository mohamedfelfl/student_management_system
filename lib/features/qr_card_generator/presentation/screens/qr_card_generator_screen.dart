import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../cubits/qr_card_cubit.dart';
import '../../cubits/qr_card_state.dart';
import '../../models/student_card_data.dart';
import '../../services/qr_card_export_service.dart';
import '../widgets/qr_card_control_bar.dart';
import '../widgets/qr_card_preview_panel.dart';
import '../widgets/qr_card_template_widget.dart';
import '../widgets/student_selection_panel.dart';

@RoutePage()
class QrCardGeneratorScreen extends StatefulWidget {
  const QrCardGeneratorScreen({super.key});

  @override
  State<QrCardGeneratorScreen> createState() => _QrCardGeneratorScreenState();
}

class _QrCardGeneratorScreenState extends State<QrCardGeneratorScreen> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final IQrCardExportService _exportService = QrCardExportService();

  @override
  void initState() {
    super.initState();
    context.read<QrCardCubit>().loadInitialData();
  }

  Future<void> _handleSingleExport(StudentCardData student) async {
    final cubit = context.read<QrCardCubit>();
    cubit.updateExportProgress(0.5, 'جاري إنشاء الصورة...');

    final String? savedPath = await _exportService.saveSingleCardImage(
      boundaryKey: _previewBoundaryKey,
      student: student,
    );

    if (savedPath != null) {
      cubit.finishExport(successMessage: 'تم حفظ بطاقة الطالب بنجاح: $savedPath');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ بطاقة الطالب بنجاح في: $savedPath',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      cubit.finishExport();
    }
  }

  Future<void> _handleBatchExport(
    List<StudentCardData> allFiltered,
    Set<int> selectedIds,
  ) async {
    final cubit = context.read<QrCardCubit>();
    final targetStudents = allFiltered
        .where((s) => selectedIds.contains(s.id))
        .toList();

    if (targetStudents.isEmpty) return;

    final String? resultDir = await _exportService.exportBatchCardsToDirectory(
      students: targetStudents,
      cardWidgetBuilder: (student) => QrCardTemplateWidget(student: student),
      onProgress: (current, total, name) {
        cubit.updateExportProgress(
          current / total,
          'جاري معالجة بطاقات الطلاب ($current / $total): $name',
        );
      },
    );

    if (resultDir != null) {
      cubit.finishExport(
        successMessage: 'تم تصدير ${targetStudents.length} بطاقة بنجاح إلى المجسّر: $resultDir',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تصدير ${targetStudents.length} بطاقة بنجاح إلى المجلد المحدد',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      cubit.finishExport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: BlocConsumer<QrCardCubit, QrCardState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!, style: GoogleFonts.cairo()),
                backgroundColor: colorScheme.error,
              ),
            );
            context.read<QrCardCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Title (Centered, No Icon, No Subtitle)
                Center(
                  child: Text(
                    'منشئ بطاقات QR للطلاب',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Top Control Bar (Mode Dropdown + Search + Filters)
                QrCardControlBar(
                  selectionMode: state.selectionMode,
                  onSelectionModeChanged: (mode) {
                    if (mode != null) {
                      context.read<QrCardCubit>().setSelectionMode(mode);
                    }
                  },
                  searchQuery: state.searchQuery,
                  onSearchChanged: (q) =>
                      context.read<QrCardCubit>().updateSearchQuery(q),
                  availableGroups: state.availableGroups,
                  selectedGroupId: state.selectedGroupId,
                  onGroupChanged: (gId) =>
                      context.read<QrCardCubit>().selectGroupFilter(gId),
                  availableStages: state.availableStages,
                  selectedStage: state.selectedStage,
                  onStageChanged: (stage) =>
                      context.read<QrCardCubit>().selectStageFilter(stage),
                ),

                const SizedBox(height: 16),

                // Main Split View Layout (Left Preview Panel, Right Selection List)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Live Preview Panel (Flex 5)
                      Expanded(
                        flex: 5,
                        child: QrCardPreviewPanel(
                          student: state.activePreviewStudent,
                          boundaryKey: _previewBoundaryKey,
                          isExporting: state.isExporting,
                          onExportSingle: () {
                            if (state.activePreviewStudent != null) {
                              _handleSingleExport(state.activePreviewStudent!);
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right Panel: Student List & Checkbox Selection (Flex 4)
                      Expanded(
                        flex: 4,
                        child: StudentSelectionPanel(
                          students: state.filteredStudents,
                          selectedStudentIds: state.selectedStudentIds,
                          activePreviewStudent: state.activePreviewStudent,
                          onStudentSelectedForPreview: (student) {
                            context
                                .read<QrCardCubit>()
                                .selectStudentForPreview(student);
                          },
                          onToggleSelection: (sId) {
                            context
                                .read<QrCardCubit>()
                                .toggleStudentSelection(sId);
                          },
                          onToggleSelectAll: (val) {
                            context.read<QrCardCubit>().toggleSelectAll(val);
                          },
                          onBatchExport: () {
                            _handleBatchExport(
                              state.filteredStudents,
                              state.selectedStudentIds,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
