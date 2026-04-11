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
  final int? studentId;
  const MarkEntryScreen({super.key, this.id, this.studentId});

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  bool _isSaving = false;
  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, GlobalKey> _studentKeys = {};
  bool _hasScrolled = false;
  int? _highlightedStudentId;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _highlightedStudentId = widget.studentId;
    if (widget.id != null) {
      context.read<ExamCubit>().loadExams();
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

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || _isSaving) return;
        
        setState(() => _isSaving = true);
        await _saveAll(showSnackbar: false);
        
        if (context.mounted) {
          setState(() {
            _canPop = true;
            _isSaving = false;
          });
          // Schedule the pop after the frame where PopScope rebuilds with canPop: true
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
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
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Pre-fill existing marks
                        // Modified pre-fill: update if empty to handle late-loading marks
                        for (final Map<String, Object?> mark
                            in examState.marks) {
                          final int sId = mark['student_id'] as int;
                          final scoreStr = (mark['score'] as num?)?.toString() ?? '';
                          if (!_scoreControllers.containsKey(sId)) {
                            _scoreControllers[sId] = TextEditingController(text: scoreStr);
                          } else if (_scoreControllers[sId]!.text.isEmpty && scoreStr.isNotEmpty) {
                            _scoreControllers[sId]!.text = scoreStr;
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: grouped.entries.map((groupEntry) {
                                final groupName = groupEntry.key;
                                final groupStudents = groupEntry.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                                      final int studentId =
                                          student['id'] as int;
                                      _scoreControllers.putIfAbsent(
                                        studentId,
                                        () => TextEditingController(),
                                      );
                                      _studentKeys.putIfAbsent(
                                        studentId,
                                        () => GlobalKey(),
                                      );

                                      if (widget.studentId != null &&
                                          !_hasScrolled &&
                                          widget.studentId == studentId) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (_studentKeys[studentId]
                                                      ?.currentContext !=
                                                  null) {
                                                Scrollable.ensureVisible(
                                                  _studentKeys[studentId]!
                                                      .currentContext!,
                                                  duration: const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  alignment: 0.5,
                                                );
                                                if (mounted) {
                                                  setState(() {
                                                    _hasScrolled = true;
                                                  });
                                                  Future.delayed(
                                                    const Duration(seconds: 2),
                                                    () {
                                                      if (mounted) {
                                                        setState(() {
                                                          _highlightedStudentId =
                                                              null;
                                                        });
                                                      }
                                                    },
                                                  );
                                                }
                                              }
                                            });
                                      }

                                      final isHighlighted =
                                          _highlightedStudentId == studentId;

                                      return AnimatedContainer(
                                        duration: const Duration(seconds: 1),
                                        key: _studentKeys[studentId],
                                        color: isHighlighted
                                            ? colorScheme.primaryContainer
                                                  .withValues(alpha: 0.3)
                                            : Colors.transparent,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 8,
                                          ),
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
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  student['name']?.toString() ??
                                                      '',
                                                  style: textTheme.bodyLarge,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: ValueListenableBuilder<TextEditingValue>(
                                                  valueListenable:
                                                      _scoreControllers[studentId]!,
                                                  builder: (context, value, child) {
                                                    Color? fillColor;
                                                    if (widget.id != null) {
                                                      final exam = examState
                                                          .exams
                                                          .firstWhere(
                                                            (e) =>
                                                                e['id'] ==
                                                                widget.id,
                                                            orElse: () =>
                                                                <
                                                                  String,
                                                                  dynamic
                                                                >{},
                                                          );
                                                      final fullMark =
                                                          (exam['full_mark']
                                                                  as num?)
                                                              ?.toDouble() ??
                                                          100.0;
                                                      final markText =
                                                          value.text;

                                                      if (markText.isNotEmpty) {
                                                        final mark =
                                                            double.tryParse(
                                                              markText,
                                                            );
                                                        if (mark != null) {
                                                          final ratio =
                                                              (mark / fullMark)
                                                                  .clamp(
                                                                    0.0,
                                                                    1.0,
                                                                  );
                                                          if (ratio > 0.5) {
                                                            fillColor =
                                                                Color.lerp(
                                                                  Colors.yellow,
                                                                  Colors.green,
                                                                  (ratio -
                                                                          0.5) *
                                                                      2,
                                                                )?.withValues(
                                                                  alpha: 0.3,
                                                                );
                                                          } else if (ratio <
                                                              0.5) {
                                                            fillColor =
                                                                Color.lerp(
                                                                  Colors.red,
                                                                  Colors.yellow,
                                                                  ratio * 2,
                                                                )?.withValues(
                                                                  alpha: 0.3,
                                                                );
                                                          } else {
                                                            fillColor = Colors
                                                                .yellow
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                );
                                                          }
                                                        }
                                                      }
                                                    }

                                                    return TextField(
                                                      controller:
                                                          _scoreControllers[studentId],
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(r'^\d*\.?\d*'),
                                                        ),
                                                      ],
                                                      decoration: InputDecoration(
                                                        hintText: LocaleKeys
                                                            .score
                                                            .tr(),
                                                        isDense: true,
                                                        filled:
                                                            fillColor != null,
                                                        fillColor: fillColor,
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                      onChanged: (val) {
                                                        if (widget.id != null) {
                                                          final exam = examState
                                                              .exams
                                                              .where(
                                                                (e) =>
                                                                    e['id'] ==
                                                                    widget.id,
                                                              )
                                                              .firstOrNull;
                                                          if (exam == null) return;
                                                          final fullMark =
                                                              (exam['full_mark']
                                                                      as num)
                                                                  .toDouble();
                                                          final mark =
                                                              double.tryParse(
                                                                val,
                                                              );
                                                          if (mark != null &&
                                                              mark > fullMark) {
                                                            _scoreControllers[studentId]
                                                                    ?.text =
                                                                fullMark
                                                                    .toString();
                                                            _scoreControllers[studentId]
                                                                    ?.selection =
                                                                TextSelection.fromPosition(
                                                                  TextPosition(
                                                                    offset: _scoreControllers[studentId]!
                                                                        .text
                                                                        .length,
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
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
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
      ),
    );
  }

  Future<void> _saveAll({bool showSnackbar = true}) async {
    if (widget.id == null || _isSaving && showSnackbar) return;

    if (showSnackbar) setState(() => _isSaving = true);

    try {
      final Map<int, double> scores = <int, double>{};
      for (final MapEntry<int, TextEditingController> entry
          in _scoreControllers.entries) {
        final double? score = double.tryParse(entry.value.text);
        if (score != null) {
          scores[entry.key] = score;
        }
      }

      if (scores.isNotEmpty) {
        await context.read<ExamCubit>().saveMarksQuietly(widget.id!, scores);
        // Added a tiny delay to ensure DB write is finalized in SQLite
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (showSnackbar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocaleKeys.marks_saved_success.tr())),
          );
        }
      }
    } finally {
      if (showSnackbar && mounted) setState(() => _isSaving = false);
    }
  }
}
