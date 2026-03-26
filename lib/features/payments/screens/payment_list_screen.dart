import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/shared/screens/shell_screen.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../../../generated/locale_keys.g.dart';
import '../../students/cubits/student_cubit.dart';
import '../cubits/payment_cubit.dart';

@RoutePage()
class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, Object?>? _selectedStudent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          LocaleKeys.payments_tracking.tr(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: Column(
          children: [
            // Top Search / Overview
            if (_selectedStudent == null)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(32.r),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 64.r,
                            color: colorScheme.primary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            LocaleKeys.select_student_account.tr(),
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            LocaleKeys.search_payment_desc.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: LocaleKeys.search_hint.tr(),
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (String q) =>
                                context.read<StudentCubit>().search(q),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Expanded(
                      child: BlocBuilder<StudentCubit, StudentState>(
                        builder: (BuildContext context, StudentState state) {
                          if (state.students.isEmpty &&
                              _searchController.text.isNotEmpty) {
                            return Center(
                              child: Text(
                                LocaleKeys.no_students_found.tr(),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: state.students.length,
                            separatorBuilder: (BuildContext _, int index) =>
                                SizedBox(height: 8.h),
                            itemBuilder: (BuildContext context, int i) {
                              final Map<String, Object?> s = state.students[i];
                              return ListTile(
                                tileColor: colorScheme.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    (s['name']?.toString() ?? 'S')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s['name']?.toString() ?? '',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  LocaleKeys.student_id_prefix.tr(
                                    args: [s['serial_number'].toString()],
                                  ),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () {
                                  setState(() => _selectedStudent = s);
                                  context.read<PaymentCubit>().loadPayments(
                                    s['id'] as int,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: BlocBuilder<PaymentCubit, PaymentState>(
                  builder: (BuildContext context, PaymentState state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Calculate totals from student's payments
                    double totalDue = 0;
                    double totalPaid = 0;
                    for (Map<String, Object?> p in state.payments) {
                      totalDue += (p['total_amount'] as num).toDouble();
                      totalPaid += (p['paid_amount'] as num).toDouble();
                    }
                    double remaining = totalDue - totalPaid;
                    if (remaining < 0) remaining = 0;

                    final double progress = totalDue > 0
                        ? (totalPaid / totalDue).clamp(0.0, 1.0)
                        : 0.0;
                    final outlineColor = colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    );

                    return RefreshIndicator(
                      onRefresh: () => context
                          .read<PaymentCubit>()
                          .loadPayments(_selectedStudent!['id'] as int),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    LocaleKeys.total_payments.tr(
                                      args: [
                                        NumberFormat('#,##0').format(totalPaid),
                                        NumberFormat('#,##0').format(totalDue),
                                      ],
                                    ),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () =>
                                      setState(() => _selectedStudent = null),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),

                            // Circular Progress Card
                            Container(
                              padding: EdgeInsets.all(32.r),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(32.r),
                                border: Border.all(color: outlineColor),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 160.r,
                                    height: 160.r,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: 1.0,
                                          strokeWidth: 16.r,
                                          valueColor: AlwaysStoppedAnimation(
                                            colorScheme.surfaceContainerHigh,
                                          ),
                                        ),
                                        CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 16.r,
                                          strokeCap: StrokeCap.round,
                                          valueColor: AlwaysStoppedAnimation(
                                            colorScheme.primary,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '${(progress * 100).toInt()}%',
                                            style: textTheme.displayMedium
                                                ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  Text(
                                    LocaleKeys.overall_payment_status.tr(),
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    progress >= 1.0
                                        ? LocaleKeys.payment_success_msg.tr()
                                        : LocaleKeys.payment_ontrack_msg.tr(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Remaining Balance Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: outlineColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      LocaleKeys.currently_due.tr(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    LocaleKeys.remaining_balance.tr(),
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${NumberFormat('#,##0.00').format(remaining)}',
                                    style: textTheme.displayLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          LocaleKeys.payment_deadline_msg.tr(),
                                          style: textTheme.labelSmall?.copyWith(
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Action Row
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showAddPaymentDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(LocaleKeys.pay_now.tr()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Transactions List
                            Text(
                              LocaleKeys.transaction_record.tr(),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (state.payments.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    LocaleKeys.no_transactions.tr(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.payments.length,
                                itemBuilder: (context, i) {
                                  final p = state.payments[i];
                                  final total = (p['total_amount'] as num)
                                      .toDouble();
                                  final paid = (p['paid_amount'] as num)
                                      .toDouble();
                                  final isPaid = paid >= total;

                                  return GestureDetector(
                                    onTap: () =>
                                        _showEditPaymentDialog(context, p),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: outlineColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isPaid
                                                  ? Colors.green.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.orange.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPaid
                                                  ? Icons.check_circle_outline
                                                  : Icons.pending_actions,
                                              color: isPaid
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  LocaleKeys.semester_fee.tr(
                                                    args: [
                                                      '${p['month']}/${p['year']}',
                                                    ],
                                                  ),
                                                  style: textTheme.titleSmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '#TRX-88${p['id']}',
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '\$${NumberFormat('#,##0.00').format(total)}',
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isPaid
                                                    ? LocaleKeys.completed.tr()
                                                    : LocaleKeys.pending.tr(),
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: isPaid
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            color: colorScheme.error,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    LocaleKeys.delete.tr(),
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this payment record?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child: Text(
                                                        LocaleKeys.cancel.tr(),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .error,
                                                          ),
                                                      onPressed: () {
                                                        context
                                                            .read<
                                                              PaymentCubit
                                                            >()
                                                            .deletePayment(
                                                              p['id'] as int,
                                                              _selectedStudent!['id']
                                                                  as int,
                                                            );
                                                        Navigator.pop(ctx);
                                                      },
                                                      child: Text(
                                                        LocaleKeys.delete.tr(),
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.onError,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    if (_selectedStudent == null) return;

    final totalController = TextEditingController();
    final paidController = TextEditingController();

    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final payments = context.read<PaymentCubit>().state.payments;

    Map<String, Object?>? findExistingPayment(int m, int y) {
      try {
        return payments.firstWhere((p) => p['month'] == m && p['year'] == y);
      } catch (_) {
        return null;
      }
    }

    void updateControllers(int m, int y) {
      final existing = findExistingPayment(m, y);
      if (existing != null) {
        totalController.text = existing['total_amount'].toString();
        paidController.clear();
      } else {
        totalController.clear();
        paidController.clear();
      }
    }

    // Initialize for current month/year
    updateControllers(selectedMonth, selectedYear);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setDialogState) {
          final existing = findExistingPayment(selectedMonth, selectedYear);
          final bool exists = existing != null;
          final double existingTotal = exists
              ? (existing['total_amount'] as num).toDouble()
              : 0.0;
          final double existingPaid = exists
              ? (existing['paid_amount'] as num).toDouble()
              : 0.0;
          final bool isFullyPaid = exists && existingPaid >= existingTotal;

          return AlertDialog(
            title: Text(LocaleKeys.add_payment.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.month.tr(),
                        ),
                        items: List.generate(
                          12,
                          (int i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (int? v) {
                          setDialogState(() {
                            selectedMonth = v!;
                            errorMessage = null;
                            updateControllers(selectedMonth, selectedYear);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.year.tr(),
                        ),
                        items: List.generate(
                          5,
                          (int i) => DropdownMenuItem<int>(
                            value: DateTime.now().year + i - 1,
                            child: Text('${DateTime.now().year + i - 1}'),
                          ),
                        ),
                        onChanged: (int? v) {
                          setDialogState(() {
                            selectedYear = v!;
                            errorMessage = null;
                            updateControllers(selectedMonth, selectedYear);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (exists) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFullyPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFullyPaid
                              ? 'Month Completed'
                              : 'Existing Payment Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isFullyPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Total: \$${existingTotal.toStringAsFixed(2)}'),
                        Text('Paid: \$${existingPaid.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: LocaleKeys.total_amount.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                if (isFullyPaid)
                  Text(
                    'Month already paid. Prevent paying amount more than total amount.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  TextField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: exists
                          ? 'Additional Paid Amount'
                          : LocaleKeys.paid_amount.tr(),
                      errorText: errorMessage,
                      helperText: exists
                          ? 'Remaining: \$${(existingTotal - existingPaid).clamp(0.0, double.infinity).toStringAsFixed(2)}'
                          : null,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              ElevatedButton(
                onPressed: isFullyPaid
                    ? null
                    : () {
                        final total =
                            double.tryParse(totalController.text) ?? 0;
                        final paid = double.tryParse(paidController.text) ?? 0;

                        if (total > 0) {
                          if ((existingPaid + paid) > total) {
                            setDialogState(() {
                              errorMessage =
                                  'Cannot pay more than the total amount.';
                            });
                            return;
                          }

                          context.read<PaymentCubit>().addOrUpdateMonthPayment(
                            studentId: _selectedStudent!['id'] as int,
                            month: selectedMonth,
                            year: selectedYear,
                            totalAmount: total,
                            paidAmount: paid,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                child: Text(LocaleKeys.save.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPaymentDialog(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final totalController = TextEditingController(
      text: payment['total_amount'].toString(),
    );
    final paidController = TextEditingController(
      text: payment['paid_amount'].toString(),
    );
    final int paymentId = payment['id'] as int;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setDialogState) {
          return AlertDialog(
            title: Text('${LocaleKeys.edit.tr()} Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${LocaleKeys.semester_fee.tr(args: ['${payment['month']}/${payment['year']}'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) {
                    if (errorMessage != null)
                      setDialogState(() => errorMessage = null);
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.total_amount.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) {
                    if (errorMessage != null)
                      setDialogState(() => errorMessage = null);
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.paid_amount.tr(),
                    errorText: errorMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  final total = double.tryParse(totalController.text) ?? 0;
                  final paid = double.tryParse(paidController.text) ?? 0;

                  if (total > 0 && paid >= 0) {
                    if (paid > total) {
                      setDialogState(() {
                        errorMessage = 'Cannot pay more than the total amount.';
                      });
                      return;
                    }

                    context.read<PaymentCubit>().updatePayment(paymentId, {
                      'total_amount': total,
                      'paid_amount': paid,
                      'student_id': _selectedStudent!['id'],
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: Text(LocaleKeys.save.tr()),
              ),
            ],
          );
        },
      ),
    );
  }
}
