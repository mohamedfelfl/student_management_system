import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/constants/dimens.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../data/models/qr_card_config.dart';
import '../../data/models/student_card_data.dart';

class QrCardControlBar extends StatelessWidget {
  final QRCardSelectionMode selectionMode;
  final ValueChanged<QRCardSelectionMode?> onSelectionModeChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Map<String, dynamic>> availableGroups;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupChanged;
  final List<String> availableStages;
  final String? selectedStage;
  final ValueChanged<String?> onStageChanged;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final void Function(DateTime? startDate, DateTime? endDate) onDateRangeChanged;

  const QrCardControlBar({
    super.key,
    required this.selectionMode,
    required this.onSelectionModeChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.availableGroups,
    required this.selectedGroupId,
    required this.onGroupChanged,
    required this.availableStages,
    required this.selectedStage,
    required this.onStageChanged,
    this.selectedStartDate,
    this.selectedEndDate,
    required this.onDateRangeChanged,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = selectedStartDate != null
        ? DateTimeRange(
            start: selectedStartDate!,
            end: selectedEndDate ?? selectedStartDate!,
          )
        : null;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }

  String _formatDateRangeText() {
    if (selectedStartDate == null) {
      return LocaleKeys.select_date_added.tr();
    }
    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(selectedStartDate!);
    if (selectedEndDate == null || _isSameDay(selectedStartDate!, selectedEndDate!)) {
      return startStr;
    }
    final endStr = formatter.format(selectedEndDate!);
    return '$startStr  →  $endStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final firstOfMonth = DateTime(now.year, now.month, 1);

    final isTodaySelected = selectedStartDate != null &&
        selectedEndDate != null &&
        _isSameDay(selectedStartDate!, today) &&
        _isSameDay(selectedEndDate!, today);

    final isYesterdaySelected = selectedStartDate != null &&
        selectedEndDate != null &&
        _isSameDay(selectedStartDate!, yesterday) &&
        _isSameDay(selectedEndDate!, yesterday);

    final is7DaysSelected = selectedStartDate != null &&
        selectedEndDate != null &&
        _isSameDay(selectedStartDate!, sevenDaysAgo) &&
        _isSameDay(selectedEndDate!, today);

    final isMonthSelected = selectedStartDate != null &&
        selectedEndDate != null &&
        _isSameDay(selectedStartDate!, firstOfMonth) &&
        _isSameDay(selectedEndDate!, today);

    return Container(
      padding: EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppDimens.opacityHalf,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<QRCardSelectionMode>(
                  isExpanded: true,
                  initialValue: selectionMode,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.select_by.tr(),
                    labelStyle: textTheme.bodyMedium,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: QRCardSelectionMode.student,
                      child: Text(
                        LocaleKeys.student_selected_mode.tr(),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    DropdownMenuItem(
                      value: QRCardSelectionMode.group,
                      child: Text(
                        LocaleKeys.group_mode.tr(),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    DropdownMenuItem(
                      value: QRCardSelectionMode.stage,
                      child: Text(
                        LocaleKeys.stage_mode.tr(),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    DropdownMenuItem(
                      value: QRCardSelectionMode.date,
                      child: Text(
                        LocaleKeys.date_mode.tr(),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    DropdownMenuItem(
                      value: QRCardSelectionMode.all,
                      child: Text(
                        LocaleKeys.all_students_mode.tr(),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  onChanged: onSelectionModeChanged,
                ),
              ),

              if (selectionMode == QRCardSelectionMode.group) ...[
                SizedBox(width: AppDimens.p12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedGroupId,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.select_group.tr(),
                      labelStyle: textTheme.bodyMedium,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimens.p12,
                        vertical: AppDimens.p10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.r10),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          LocaleKeys.all_groups.tr(),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      ...availableGroups.map((g) {
                        final id = g['id'] as int;
                        final name = g['name'] as String? ?? '';
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            name,
                            style: textTheme.bodyMedium,
                          ),
                        );
                      }),
                    ],
                    onChanged: onGroupChanged,
                  ),
                ),
              ],

              if (selectionMode == QRCardSelectionMode.stage) ...[
                SizedBox(width: AppDimens.p12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedStage,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.select_stage.tr(),
                      labelStyle: textTheme.bodyMedium,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimens.p12,
                        vertical: AppDimens.p10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.r10),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          LocaleKeys.all_stages.tr(),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      ...availableStages.map((stage) {
                        return DropdownMenuItem<String>(
                          value: stage,
                          child: Text(
                            StudentCardData.formatStageArabic(stage),
                            style: textTheme.bodyMedium,
                          ),
                        );
                      }),
                    ],
                    onChanged: onStageChanged,
                  ),
                ),
              ],

              if (selectionMode == QRCardSelectionMode.date) ...[
                SizedBox(width: AppDimens.p12),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _pickDateRange(context),
                    borderRadius: BorderRadius.circular(AppDimens.r10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: LocaleKeys.date_mode.tr(),
                        labelStyle: textTheme.bodyMedium,
                        prefixIcon: Icon(
                          Icons.calendar_month_rounded,
                          size: AppDimens.iconSize20,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: selectedStartDate != null
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: AppDimens.iconSize18,
                                ),
                                onPressed: () => onDateRangeChanged(null, null),
                                tooltip: LocaleKeys.clear_date_filter.tr(),
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimens.p12,
                          vertical: AppDimens.p10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r10),
                        ),
                      ),
                      child: Text(
                        _formatDateRangeText(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: selectedStartDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedStartDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(width: AppDimens.p12),

              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.search_student_or_code_hint.tr(),
                    hintStyle: textTheme.bodyMedium,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: AppDimens.iconSize20,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (selectionMode == QRCardSelectionMode.date) ...[
            SizedBox(height: AppDimens.p10),
            Wrap(
              spacing: AppDimens.p8,
              runSpacing: AppDimens.p6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text(LocaleKeys.filter_today.tr()),
                  selected: isTodaySelected,
                  onSelected: (_) => onDateRangeChanged(today, today),
                  avatar: const Icon(Icons.today_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: Text(LocaleKeys.filter_yesterday.tr()),
                  selected: isYesterdaySelected,
                  onSelected: (_) => onDateRangeChanged(yesterday, yesterday),
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: Text(LocaleKeys.filter_last_7_days.tr()),
                  selected: is7DaysSelected,
                  onSelected: (_) => onDateRangeChanged(sevenDaysAgo, today),
                  avatar: const Icon(Icons.date_range_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: Text(LocaleKeys.filter_this_month.tr()),
                  selected: isMonthSelected,
                  onSelected: (_) => onDateRangeChanged(firstOfMonth, today),
                  avatar: const Icon(Icons.calendar_view_month_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
                if (selectedStartDate != null)
                  ActionChip(
                    label: Text(LocaleKeys.clear_date_filter.tr()),
                    onPressed: () => onDateRangeChanged(null, null),
                    avatar: const Icon(Icons.clear_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
