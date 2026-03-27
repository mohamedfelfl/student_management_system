import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../cubits/payment_cubit.dart';
import 'components/payment_stats_card.dart';
import 'components/remaining_balance_card.dart';
import 'components/student_search_section.dart';
import 'components/transaction_tile.dart';

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
                    Scaffold.of(context).openDrawer(),
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
                child: StudentSearchSection(
                  searchController: _searchController,
                  onStudentSelected: (s) => setState(() => _selectedStudent = s),
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
                    Map<String, double> monthlyDue = {};
                    double totalPaid = 0;
                    for (Map<String, Object?> p in state.payments) {
                      final key = "${p['month']}-${p['year']}";
                      monthlyDue[key] = (p['total_amount'] as num).toDouble();
                      totalPaid += (p['paid_amount'] as num).toDouble();
                    }
                    double totalDue = monthlyDue.values.fold(0.0, (sum, val) => sum + val);
                    double remaining = totalDue - totalPaid;
                    if (remaining < 0) remaining = 0;

                    final double progress = totalDue > 0
                        ? (totalPaid / totalDue).clamp(0.0, 1.0)
                        : 0.0;

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
                            PaymentStatsCard(progress: progress),
                            const SizedBox(height: 16),

                            // Remaining Balance Card
                            RemainingBalanceCard(remaining: remaining),
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
                                  return TransactionTile(
                                    payment: p,
                                    onTap: () => _showEditPaymentDialog(context, p),
                                    onDelete: () {
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

    List<Map<String, dynamic>> findMonthlyPayments(int m, int y) {
      return payments.where((p) => p['month'] == m && p['year'] == y).toList();
    }

    void updateControllers(int m, int y) {
      final monthlyResults = findMonthlyPayments(m, y);
      if (monthlyResults.isNotEmpty) {
        totalController.text = monthlyResults.first['total_amount'].toString();
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
          final monthlyResults = findMonthlyPayments(selectedMonth, selectedYear);
          final bool exists = monthlyResults.isNotEmpty;
          final double existingTotal = exists
              ? (monthlyResults.first['total_amount'] as num).toDouble()
              : 0.0;
          final double existingPaid = monthlyResults.fold(
            0.0,
            (sum, p) => sum + (p['paid_amount'] as num).toDouble(),
          );
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
                        initialValue: selectedMonth,
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
                        initialValue: selectedYear,
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
                        Text('Total: EGP ${existingTotal.toStringAsFixed(2)}'),
                        Text('Paid: EGP ${existingPaid.toStringAsFixed(2)}'),
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
                          ? 'Remaining: EGP ${(existingTotal - existingPaid).clamp(0.0, double.infinity).toStringAsFixed(2)}'
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

                          context.read<PaymentCubit>().addPaymentTransaction(
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
                  LocaleKeys.semester_fee.tr(args: ['${payment['month']}/${payment['year']}']),
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
                    if (errorMessage != null) {
                      setDialogState(() => errorMessage = null);
                    }
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
                    if (errorMessage != null) {
                      setDialogState(() => errorMessage = null);
                    }
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
