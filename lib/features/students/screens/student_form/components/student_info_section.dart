import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/constants/dimens.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Personal info fields: name, address, phones, father job, school, previous teacher.
class StudentInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phone1Controller;
  final TextEditingController phone2Controller;
  final TextEditingController fatherJobController;
  final TextEditingController schoolController;
  final TextEditingController previousTeacherController;

  const StudentInfoSection({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phone1Controller,
    required this.phone2Controller,
    required this.fatherJobController,
    required this.schoolController,
    required this.previousTeacherController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: LocaleKeys.name.tr(),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? LocaleKeys.required_field.tr() : null,
        ),
        SizedBox(height: AppDimens.h24),

        // Address
        TextFormField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: LocaleKeys.address.tr(),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        SizedBox(height: AppDimens.h24),

        // Phones
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: phone1Controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: InputDecoration(
                  labelText: LocaleKeys.phone1.tr(),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
            SizedBox(width: AppDimens.w16),
            Expanded(
              child: TextFormField(
                controller: phone2Controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: InputDecoration(
                  labelText: LocaleKeys.phone2.tr(),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.h24),

        // Father's Job
        TextFormField(
          controller: fatherJobController,
          decoration: InputDecoration(
            labelText: LocaleKeys.father_job.tr(),
            prefixIcon: const Icon(Icons.work_outline),
          ),
        ),
        SizedBox(height: AppDimens.h24),

        // School
        TextFormField(
          controller: schoolController,
          decoration: InputDecoration(
            labelText: LocaleKeys.school.tr(),
            prefixIcon: const Icon(Icons.school_outlined),
          ),
        ),
        SizedBox(height: AppDimens.h24),

        // Previous Teacher
        TextFormField(
          controller: previousTeacherController,
          decoration: InputDecoration(
            labelText: LocaleKeys.previous_teacher.tr(),
            prefixIcon: const Icon(Icons.person_search_outlined),
          ),
        ),
        SizedBox(height: AppDimens.h24),
      ],
    );
  }
}
