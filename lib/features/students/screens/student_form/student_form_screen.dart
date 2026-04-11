import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../groups/cubits/group_cubit.dart';
import '../../cubits/student_cubit.dart';

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
      // Ensure the grade exists in our predefined keys to avoid DropdownButton assertion failure
      const List<String> validGrades = [
        'primary_1', 'primary_2', 'primary_3', 'primary_4', 'primary_5', 'primary_6',
        'prep_1', 'prep_2', 'prep_3',
        'sec_1', 'sec_2', 'sec_3'
      ];
      _selectedGrade = validGrades.contains(gradeValue) ? gradeValue : null;

      _selectedStatus = student['student_status']?.toString() ?? 'normal';
      
      final String? dayValue = student['attendance_day']?.toString();
      // Ensure the day exists in our predefined keys to avoid DropdownButton assertion failure
      const List<String> validDays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : IconButton(
                onPressed: () => context.router.maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const SizedBox(height: 28),

                  // Serial Number
                  TextFormField(
                    controller: _serialController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.serial_number.tr(),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? LocaleKeys.required_field.tr()
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.name.tr(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? LocaleKeys.required_field.tr()
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.address.tr(),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phones
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phone1Controller,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.phone1.tr(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phone2Controller,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.phone2.tr(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Father's Job
                  TextFormField(
                    controller: _fatherJobController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.father_job.tr(),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // School
                  TextFormField(
                    controller: _schoolController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.school.tr(),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Previous Teacher
                  TextFormField(
                    controller: _previousTeacherController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.previous_teacher.tr(),
                      prefixIcon: const Icon(Icons.person_search_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grade Dropdown
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedGrade,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.grade.tr(),
                      prefixIcon: const Icon(Icons.school),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(LocaleKeys.not_specified.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_1',
                        child: Text(LocaleKeys.primary_1.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_2',
                        child: Text(LocaleKeys.primary_2.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_3',
                        child: Text(LocaleKeys.primary_3.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_4',
                        child: Text(LocaleKeys.primary_4.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_5',
                        child: Text(LocaleKeys.primary_5.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'primary_6',
                        child: Text(LocaleKeys.primary_6.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'prep_1',
                        child: Text(LocaleKeys.prep_1.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'prep_2',
                        child: Text(LocaleKeys.prep_2.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'prep_3',
                        child: Text(LocaleKeys.prep_3.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'sec_1',
                        child: Text(LocaleKeys.sec_1.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'sec_2',
                        child: Text(LocaleKeys.sec_2.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'sec_3',
                        child: Text(LocaleKeys.sec_3.tr()),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedGrade = v),
                  ),
                  const SizedBox(height: 24),

                  // Student Status Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.student_status.tr(),
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'normal',
                        child: Text(LocaleKeys.normal.tr()),
                      ),
                      DropdownMenuItem<String>(
                        value: 'free',
                        child: Text(LocaleKeys.free.tr()),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                  const SizedBox(height: 24),

                  // Group Dropdown
                  BlocBuilder<GroupCubit, GroupState>(
                    builder: (BuildContext context, GroupState groupState) {
                      final bool valueExists = groupState.groups.any(
                        (g) => g['id'] == _selectedGroupId,
                      );

                      return DropdownButtonFormField<int?>(
                        initialValue: valueExists ? _selectedGroupId : null,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.groups.tr(),
                          prefixIcon: const Icon(Icons.groups_outlined),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(LocaleKeys.no_group.tr()),
                          ),
                          ...groupState.groups.map(
                            (Map<String, Object?> g) => DropdownMenuItem<int?>(
                              value: g['id'] as int,
                              child: Text(g['name']?.toString() ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedGroupId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Attendance Day Dropdown
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedAttendanceDay,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.attendance_day.tr(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(LocaleKeys.not_specified.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Monday',
                        child: Text(LocaleKeys.monday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Tuesday',
                        child: Text(LocaleKeys.tuesday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Wednesday',
                        child: Text(LocaleKeys.wednesday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Thursday',
                        child: Text(LocaleKeys.thursday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Friday',
                        child: Text(LocaleKeys.friday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Saturday',
                        child: Text(LocaleKeys.saturday.tr()),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Sunday',
                        child: Text(LocaleKeys.sunday.tr()),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedAttendanceDay = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
    if (_isEditing) {
      await cubit.updateStudent(widget.id!, data);
    } else {
      await cubit.createStudent(data);
    }

    if (mounted) {
      context.router.maybePop();
    }
  }
}
