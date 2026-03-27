import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:student_management_system/generated/locale_keys.g.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';
import 'package:student_management_system/features/payments/cubits/payment_cubit.dart';

class StudentSearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final Function(Map<String, Object?>) onStudentSelected;

  const StudentSearchSection({
    super.key,
    required this.searchController,
    required this.onStudentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 64.r,
                color: colorScheme.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                LocaleKeys.select_student_account.tr(),
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                LocaleKeys.search_payment_desc.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: searchController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: LocaleKeys.search_hint.tr(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (String q) => context.read<StudentCubit>().search(q),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Expanded(
          child: BlocBuilder<StudentCubit, StudentState>(
            builder: (BuildContext context, StudentState state) {
              if (state.students.isEmpty && searchController.text.isNotEmpty) {
                return Center(
                  child: Text(
                    LocaleKeys.no_students_found.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: state.students.length,
                separatorBuilder: (BuildContext _, int index) =>
                    SizedBox(height: 8.h),
                itemBuilder: (BuildContext context, int i) {
                  final Map<String, Object?> s = state.students[i];
                  return ListTile(
                    tileColor: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        (s['name']?.toString() ?? 'S')[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      s['name']?.toString() ?? '',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      LocaleKeys.student_id_prefix.tr(
                        args: [s['serial_number'].toString()],
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      onStudentSelected(s);
                      context.read<PaymentCubit>().loadPayments(s['id'] as int);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
