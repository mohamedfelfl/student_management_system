import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';
import '../cubits/exam_cubit.dart';
import '../../students/cubits/student_cubit.dart';

@RoutePage()
class MarkEntryScreen extends StatefulWidget {
  final int? id;
  const MarkEntryScreen({super.key, this.id});

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  final Map<int, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      context.read<ExamCubit>().loadMarks(widget.id!);
    }
    context.read<StudentCubit>().loadStudents();
  }

  @override
  void dispose() {
    for (final TextEditingController c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.router.maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(LocaleKeys.grade_entry.tr(), style: textTheme.headlineLarge)),
                ElevatedButton.icon(
                  onPressed: _saveAll,
                  icon: const Icon(Icons.save),
                  label: Text(LocaleKeys.save_all.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<StudentCubit, StudentState>(
                builder: (BuildContext context, StudentState studentState) {
                  return BlocBuilder<ExamCubit, ExamState>(
                    builder: (BuildContext context, ExamState examState) {
                      if (studentState.isLoading || examState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<Map<String, Object?>> students = studentState.students;
                      // Pre-fill existing marks
                      for (final Map<String, Object?> mark in examState.marks) {
                        final int sId = mark['student_id'] as int;
                        if (!_scoreControllers.containsKey(sId)) {
                          _scoreControllers[sId] = TextEditingController(
                            text: (mark['score'] as num?)?.toString() ?? '',
                          );
                        }
                      }

                      return Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: students.length,
                          itemBuilder: (BuildContext context, int i) {
                            final Map<String, Object?> s = students[i];
                            final int sId = s['id'] as int;
                            _scoreControllers.putIfAbsent(sId, () => TextEditingController());

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      s['serial_number']?.toString() ?? '',
                                      style: textTheme.labelMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(s['name']?.toString() ?? '',
                                        style: textTheme.bodyLarge),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _scoreControllers[sId],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: LocaleKeys.score.tr(),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (val) {
                                        if (widget.id != null) {
                                          final exam = examState.exams.firstWhere((e) => e['id'] == widget.id);
                                          final fullMark = (exam['full_mark'] as num).toDouble();
                                          final mark = double.tryParse(val);
                                          if (mark != null && mark > fullMark) {
                                            _scoreControllers[sId]?.text = fullMark.toString();
                                            _scoreControllers[sId]?.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _scoreControllers[sId]!.text.length),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAll() {
    if (widget.id == null) return;

    final Map<int, double> scores = <int, double>{};
    for (final MapEntry<int, TextEditingController> entry in _scoreControllers.entries) {
      final double? score = double.tryParse(entry.value.text);
      if (score != null) {
        scores[entry.key] = score;
      }
    }

    if (scores.isNotEmpty) {
      context.read<ExamCubit>().saveMarks(widget.id!, scores);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.marks_saved_success.tr())),
      );
    }
  }
}
