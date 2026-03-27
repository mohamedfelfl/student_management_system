import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../exams/cubits/exam_cubit.dart';

class MarksTab extends StatelessWidget {
  final int studentId;
  const MarksTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.marks.isEmpty) {
          return Center(child: Text(LocaleKeys.no_exam_records.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.marks.length,
          itemBuilder: (context, i) {
            final m = state.marks[i];
            final score = (m['score'] as num).toDouble();
            final full = (m['exam_full_mark'] as num?)?.toDouble() ?? 0;
            final pct = full > 0 ? (score / full * 100) : 0;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['exam_name']?.toString() ?? '',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('${score.toStringAsFixed(1)} / ${full.toStringAsFixed(1)}'),
                        ],
                      ),
                    ),
                    CircularProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      color: pct >= 50 ? Colors.green : Colors.red,
                      strokeWidth: 6,
                    ),
                    const SizedBox(width: 8),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
