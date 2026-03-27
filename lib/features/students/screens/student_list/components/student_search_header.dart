import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:student_management_system/generated/locale_keys.g.dart';

class StudentSearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPressed;
  final VoidCallback? onBulkDeletePressed;
  final int? selectedCount;

  const StudentSearchHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddPressed,
    this.onBulkDeletePressed,
    this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = selectedCount != null && selectedCount! > 0;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: LocaleKeys.search_hint.tr(),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        if (hasSelection && onBulkDeletePressed != null) ...[
          ElevatedButton.icon(
            onPressed: onBulkDeletePressed,
            icon: const Icon(Icons.delete_sweep),
            label: Text(
              '${LocaleKeys.delete_selected.tr()} ($selectedCount)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 24.h,
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
        ElevatedButton.icon(
          onPressed: onAddPressed,
          icon: const Icon(Icons.person_add),
          label: Text(LocaleKeys.add_new.tr()),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
          ),
        ),
      ],
    );
  }
}
