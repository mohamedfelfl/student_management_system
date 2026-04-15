import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../cubits/exam_cubit.dart';

@RoutePage()
class ExamFormScreen extends StatefulWidget {
  final int? examId;
  const ExamFormScreen({super.key, this.examId});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fullMarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<int> _selectedGroupIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      final examState = context.read<ExamCubit>().state;
      final exam = examState.exams.firstWhere(
        (e) => e['id'] == widget.examId,
        orElse: () => <String, dynamic>{},
      );

      if (exam.isNotEmpty) {
        _nameController.text = exam['name']?.toString() ?? '';
        final fullMark = exam['full_mark'];
        _fullMarkController.text = fullMark is num
            ? fullMark.toStringAsFixed(0)
            : fullMark?.toString() ?? '';

        if (exam['date'] != null) {
          _selectedDate =
              DateTime.tryParse(exam['date'].toString()) ?? DateTime.now();
        }
      }
      _loadExamGroups();
    }
  }

  Future<void> _loadExamGroups() async {
    final groups = await context.read<ExamCubit>().getExamGroups(
      widget.examId!,
    );
    if (mounted) {
      setState(() {
        _selectedGroupIds.clear();
        _selectedGroupIds.addAll(groups);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullMarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.examId != null
              ? LocaleKeys.edit_exam.tr()
              : LocaleKeys.add_exam.tr(),
        ),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800.w),
            child: Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.examId != null
                            ? LocaleKeys.edit_exam.tr()
                            : LocaleKeys.add_exam.tr(),
                        style: textTheme.headlineLarge,
                      ),
                      SizedBox(height: 32.h),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.exam_name.tr(),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? LocaleKeys.required_field.tr()
                            : null,
                      ),
                      SizedBox(height: 20.h),
                      TextFormField(
                        controller: _fullMarkController,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.full_mark.tr(),
                          prefixIcon: const Icon(Icons.score),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => value?.isEmpty ?? true
                            ? LocaleKeys.required_field.tr()
                            : null,
                      ),
                      SizedBox(height: 20.h),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: LocaleKeys.exam_date.tr(),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat.yMMMd().format(_selectedDate)),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        LocaleKeys.link_to_groups.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      BlocBuilder<ExamCubit, ExamState>(
                        builder: (context, state) {
                          if (state.groups.isEmpty) {
                            return Text(LocaleKeys.no_groups_yet.tr());
                          }
                          return Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: state.groups.map((group) {
                              final int groupId = group['id'] as int;
                              final bool isSelected = _selectedGroupIds
                                  .contains(groupId);
                              return FilterChip(
                                label: Text(group['name'] as String),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedGroupIds.add(groupId);
                                    } else {
                                      _selectedGroupIds.remove(groupId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 48.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            widget.examId != null
                                ? LocaleKeys.update.tr()
                                : LocaleKeys.create_exam.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final examData = {
      'name': _nameController.text.trim(),
      'full_mark': double.parse(_fullMarkController.text),
      'date': _selectedDate.toIso8601String().split('T').first,
    };

    if (widget.examId != null) {
      await context.read<ExamCubit>().updateExam(
        widget.examId!,
        examData,
        groupIds: _selectedGroupIds,
      );
    } else {
      await context.read<ExamCubit>().createExam(
        examData,
        groupIds: _selectedGroupIds,
      );
    }

    if (mounted) {
      context.router.maybePop();
    }
  }
}
