import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/router/app_router.gr.dart';
import '../cubits/exam_cubit.dart';

@RoutePage()
class ExamsManagementScreen extends StatelessWidget {
  const ExamsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('exams_management'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.router.push(ExamFormRoute()),
          ),
        ],
      ),
      body: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.exams.isEmpty) {
            return Center(child: Text('no_exams'.tr()));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: state.exams.length,
            itemBuilder: (context, index) {
              final exam = state.exams[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  onTap: () => context.router.push(ExamDetailRoute(examId: exam['id'] as int)),
                  title: Text(exam['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${'full_mark'.tr()}: ${exam['full_mark']} | ${exam['date']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, exam['id'] as int),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_exam'.tr()),
        content: Text('delete_exam_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              context.read<ExamCubit>().deleteExam(id);
              Navigator.pop(context);
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
