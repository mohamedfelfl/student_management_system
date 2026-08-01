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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
      child: Row(
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
    );
  }
}
