import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../payments/cubits/payment_cubit.dart';

class PaymentsTab extends StatelessWidget {
  final int studentId;
  const PaymentsTab({super.key, required this.studentId});

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
