import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../../students/cubits/student_cubit.dart';
import '../../cubits/exam_cubit.dart';

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
      context.read<ExamCubit>().loadExamStudents(widget.id!);
    }
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
                Expanded(
                  child: Text(
                    LocaleKeys.grade_entry.tr(),
                    style: textTheme.headlineLarge,
                  ),
                ),
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

                      // Pre-fill existing marks
                      for (final Map<String, Object?> mark in examState.marks) {
                        final int sId = mark['student_id'] as int;
                        if (!_scoreControllers.containsKey(sId)) {
                          _scoreControllers[sId] = TextEditingController(
                            text: (mark['score'] as num?)?.toString() ?? '',
                          );
                        }
                      }

                      final grouped = examState.groupedExamStudents;
                      if (grouped.isEmpty) {
                        return Center(
                          child: Text(
                            LocaleKeys.no_students.tr(),
                            style: textTheme.bodyLarge,
                          ),
                        );
                      }

                      return Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: grouped.length,
                          itemBuilder: (BuildContext context, int groupIndex) {
                            final groupName = grouped.keys.elementAt(groupIndex);
                            final groupStudents = grouped[groupName]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    groupName,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Divider(),
                                ...groupStudents.map((student) {
                                  final int studentId = student['id'] as int;
                                  _scoreControllers.putIfAbsent(
                                    studentId,
                                    () => TextEditingController(),
                                  );

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            student['serial_number']
                                                    ?.toString() ??
                                                '',
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            student['name']?.toString() ?? '',
                                            style: textTheme.bodyLarge,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: ValueListenableBuilder<TextEditingValue>(
                                            valueListenable: _scoreControllers[studentId]!,
                                            builder: (context, value, child) {
                                              Color? fillColor;
                                              if (widget.id != null) {
                                                final exam = examState.exams.firstWhere(
                                                  (e) => e['id'] == widget.id,
                                                  orElse: () => <String, dynamic>{},
                                                );
                                                final fullMark = (exam['full_mark'] as num?)?.toDouble() ?? 100.0;
                                                final markText = value.text;
                                                
                                                if (markText.isNotEmpty) {
                                                  final mark = double.tryParse(markText);
                                                  if (mark != null) {
                                                    final ratio = (mark / fullMark).clamp(0.0, 1.0);
                                                    if (ratio > 0.5) {
                                                      fillColor = Color.lerp(Colors.yellow, Colors.green, (ratio - 0.5) * 2)?.withOpacity(0.3);
                                                    } else if (ratio < 0.5) {
                                                      fillColor = Color.lerp(Colors.red, Colors.yellow, ratio * 2)?.withOpacity(0.3);
                                                    } else {
                                                      fillColor = Colors.yellow.withOpacity(0.3);
                                                    }
                                                  }
                                                }
                                              }

                                              return TextField(
                                                controller: _scoreControllers[studentId],
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\d*\.?\d*'),
                                                  ),
                                                ],
                                                decoration: InputDecoration(
                                                  hintText: LocaleKeys.score.tr(),
                                                  isDense: true,
                                                  filled: fillColor != null,
                                                  fillColor: fillColor,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  if (widget.id != null) {
                                                    final exam = examState.exams.firstWhere(
                                                      (e) => e['id'] == widget.id,
                                                    );
                                                    final fullMark = (exam['full_mark'] as num).toDouble();
                                                    final mark = double.tryParse(val);
                                                    if (mark != null && mark > fullMark) {
                                                      _scoreControllers[studentId]?.text = fullMark.toString();
                                                      _scoreControllers[studentId]?.selection = TextSelection.fromPosition(
                                                        TextPosition(
                                                          offset: _scoreControllers[studentId]!.text.length,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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
    for (final MapEntry<int, TextEditingController> entry
        in _scoreControllers.entries) {
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
