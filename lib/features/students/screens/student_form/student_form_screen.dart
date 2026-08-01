import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/dimens.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../groups/cubits/group_cubit.dart';
import '../../cubits/student_cubit.dart';
import 'components/student_academic_section.dart';
import 'components/student_info_section.dart';

@RoutePage()
class StudentFormScreen extends StatefulWidget {
  final int? id;
  const StudentFormScreen({super.key, this.id});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _fatherJobController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _previousTeacherController =
      TextEditingController();
  int? _selectedGroupId;
  String? _selectedGrade;
  String _selectedStatus = 'normal';
  String? _selectedAttendanceDay;
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().loadGroups();
    if (widget.id != null) {
      _isEditing = true;
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    final Map<String, Object?>? student = await context
        .read<StudentCubit>()
        .getStudentById(widget.id!);
    if (student != null) {
      _serialController.text = student['serial_number']?.toString() ?? '';
      _nameController.text = student['name']?.toString() ?? '';
      _addressController.text = student['address']?.toString() ?? '';
      _phone1Controller.text = student['phone1']?.toString() ?? '';
      _phone2Controller.text = student['phone2']?.toString() ?? '';
      _fatherJobController.text = student['father_job']?.toString() ?? '';
      _schoolController.text = student['school']?.toString() ?? '';
      _previousTeacherController.text =
          student['previous_teacher']?.toString() ?? '';
      _selectedGroupId = student['group_id'] as int?;

      final String? gradeValue = student['grade']?.toString();
      const List<String> validGrades = [
        'primary_1',
        'primary_2',
        'primary_3',
        'primary_4',
        'primary_5',
        'primary_6',
        'prep_1',
        'prep_2',
        'prep_3',
        'sec_1',
        'sec_2',
        'sec_3',
      ];
      _selectedGrade = validGrades.contains(gradeValue) ? gradeValue : null;

      _selectedStatus = student['student_status']?.toString() ?? 'normal';

      final String? dayValue = student['attendance_day']?.toString();
      const List<String> validDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      _selectedAttendanceDay = validDays.contains(dayValue) ? dayValue : null;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _fatherJobController.dispose();
    _schoolController.dispose();
    _previousTeacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? LocaleKeys.edit_student.tr()
              : LocaleKeys.add_student.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: context.router.canPop() ? const BackButton() : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppDimens.maxFormWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppDimens.h12),
                  SizedBox(height: AppDimens.h24),

                  StudentInfoSection(
                    serialController: _serialController,
                    nameController: _nameController,
                    addressController: _addressController,
                    phone1Controller: _phone1Controller,
                    phone2Controller: _phone2Controller,
                    fatherJobController: _fatherJobController,
                    schoolController: _schoolController,
                    previousTeacherController: _previousTeacherController,
                  ),

                  StudentAcademicSection(
                    selectedGrade: _selectedGrade,
                    selectedStatus: _selectedStatus,
                    selectedGroupId: _selectedGroupId,
                    selectedAttendanceDay: _selectedAttendanceDay,
                    onGradeChanged: (v) => setState(() => _selectedGrade = v),
                    onStatusChanged: (v) => setState(() => _selectedStatus = v),
                    onGroupChanged: (v) => setState(() => _selectedGroupId = v),
                    onAttendanceDayChanged: (v) =>
                        setState(() => _selectedAttendanceDay = v),
                  ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        textStyle: textTheme.titleLarge,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? SizedBox(
                              width: AppDimens.p24,
                              height: AppDimens.p24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? LocaleKeys.update.tr()
                                  : LocaleKeys.create.tr(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final Map<String, Object?> data = {
      'serial_number': _serialController.text.trim(),
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone1': _phone1Controller.text.trim(),
      'phone2': _phone2Controller.text.trim(),
      'father_job': _fatherJobController.text.trim(),
      'school': _schoolController.text.trim(),
      'previous_teacher': _previousTeacherController.text.trim(),
      'group_id': _selectedGroupId,
      'grade': _selectedGrade,
      'student_status': _selectedStatus,
      'attendance_day': _selectedAttendanceDay,
    };

    final StudentCubit cubit = context.read<StudentCubit>();
    try {
      if (_isEditing) {
        await cubit.updateStudent(widget.id!, data);
      } else {
        await cubit.createStudent(data);
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.success.tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.router.maybePop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('UNIQUE constraint failed')) {
          errorMessage =
              'This serial number is already in use by another student.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
