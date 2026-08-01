enum QRCardSelectionMode {
  student,
  group,
  stage,
  all,
}

class QRCardConfig {
  final QRCardSelectionMode selectionMode;
  final String searchQuery;
  final int? selectedGroupId;
  final String? selectedStage;
  final Set<int> selectedStudentIds;
  final int? activePreviewStudentId;
  final bool isExporting;
  final double exportProgress;

  const QRCardConfig({
    this.selectionMode = QRCardSelectionMode.student,
    this.searchQuery = '',
    this.selectedGroupId,
    this.selectedStage,
    this.selectedStudentIds = const {},
    this.activePreviewStudentId,
    this.isExporting = false,
    this.exportProgress = 0.0,
  });

  QRCardConfig copyWith({
    QRCardSelectionMode? selectionMode,
    String? searchQuery,
    int? selectedGroupId,
    String? selectedStage,
    Set<int>? selectedStudentIds,
    int? activePreviewStudentId,
    bool? isExporting,
    double? exportProgress,
  }) {
    return QRCardConfig(
      selectionMode: selectionMode ?? this.selectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedStage: selectedStage ?? this.selectedStage,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      activePreviewStudentId:
          activePreviewStudentId ?? this.activePreviewStudentId,
      isExporting: isExporting ?? this.isExporting,
      exportProgress: exportProgress ?? this.exportProgress,
    );
  }
}
