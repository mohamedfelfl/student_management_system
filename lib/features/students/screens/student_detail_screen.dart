import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/router/app_router.gr.dart';
import '../../../generated/locale_keys.g.dart';
import '../cubits/student_cubit.dart';
import '../../payments/cubits/payment_cubit.dart';
import '../../attendance/cubits/attendance_cubit.dart';
import '../../exams/cubits/exam_cubit.dart';

@RoutePage()
class StudentDetailScreen extends StatefulWidget {
  final int id;

  const StudentDetailScreen({super.key, required this.id});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _student;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final student = await context.read<StudentCubit>().getStudentById(widget.id);
    setState(() => _student = student);

    if (mounted) {
      context.read<PaymentCubit>().loadPayments(widget.id);
      context.read<AttendanceCubit>().loadAttendance(widget.id);
      context.read<ExamCubit>().loadStudentMarks(widget.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_student == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.router.maybePop(),
                        icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.router.push(StudentFormRoute(id: widget.id)),
                        icon: Icon(Icons.edit, color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _student!['name']?.toString() ?? '',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${LocaleKeys.serial.tr(args: [_student!['serial_number'].toString()])} • ${_student!['group_name'] ?? LocaleKeys.unassigned.tr()}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: LocaleKeys.info.tr()),
              Tab(text: LocaleKeys.tab_payments.tr()),
              Tab(text: LocaleKeys.tab_attendance.tr()),
              Tab(text: LocaleKeys.tab_marks.tr()),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(student: _student!),
                _PaymentsTab(studentId: widget.id),
                _AttendanceTab(studentId: widget.id),
                _MarksTab(studentId: widget.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Map<String, dynamic> student;

  const _InfoTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _infoRow(LocaleKeys.address.tr(), student['address']?.toString() ?? '-', Icons.location_on_outlined, textTheme, colorScheme),
              _divider(),
              _infoRow(LocaleKeys.phone1.tr(), student['phone1']?.toString() ?? '-', Icons.phone, textTheme, colorScheme),
              _divider(),
              _infoRow(LocaleKeys.phone2.tr(), student['phone2']?.toString() ?? '-', Icons.phone, textTheme, colorScheme),
              _divider(),
              _infoRow(LocaleKeys.father_job.tr(), student['father_job']?.toString() ?? '-', Icons.work_outline, textTheme, colorScheme),
              _divider(),
              _infoRow(LocaleKeys.school_group.tr(), student['school']?.toString() ?? '-', Icons.school_outlined, textTheme, colorScheme),
              _divider(),
              _infoRow(LocaleKeys.previous_teacher.tr(), student['previous_teacher']?.toString() ?? '-', Icons.person_search_outlined, textTheme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, thickness: 0.5),
      );

  Widget _infoRow(String label, String value, IconData icon, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final int studentId;
  const _PaymentsTab({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.payments.isEmpty) {
          return Center(child: Text(LocaleKeys.no_payment_records.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.payments.length,
          itemBuilder: (context, i) {
            final p = state.payments[i];
            final total = (p['total_amount'] as num).toDouble();
            final paid = (p['paid_amount'] as num).toDouble();
            final remaining = total - paid;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p['month']}/${p['year']}',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(LocaleKeys.payment_summary.tr(args: [total.toStringAsFixed(2), paid.toStringAsFixed(2)])),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        remaining <= 0 ? LocaleKeys.paid.tr() : LocaleKeys.due_amount.tr(args: [remaining.toStringAsFixed(2)]),
                        style: TextStyle(
                          color: remaining <= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

class _AttendanceTab extends StatelessWidget {
  final int studentId;
  const _AttendanceTab({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.records.isEmpty) {
          return Center(child: Text(LocaleKeys.no_attendance_records.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.records.length,
          itemBuilder: (context, i) {
            final a = state.records[i];
            final status = a['status']?.toString() ?? '';
            Color chipColor;
            switch (status) {
              case 'attended':
                chipColor = Colors.green;
                break;
              case 'missed':
                chipColor = Colors.red;
                break;
              default:
                chipColor = Colors.orange;
            }

            final String statusLabel = status == 'attended' 
                ? LocaleKeys.attended.tr() 
                : status == 'missed' 
                    ? LocaleKeys.missed.tr() 
                    : status;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: chipColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a['date']?.toString() ?? '')),
                  Chip(
                    label: Text(statusLabel, style: TextStyle(color: chipColor, fontSize: 10.sp)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MarksTab extends StatelessWidget {
  final int studentId;
  const _MarksTab({required this.studentId});

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
