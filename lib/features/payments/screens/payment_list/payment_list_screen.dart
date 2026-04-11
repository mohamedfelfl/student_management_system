import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../cubits/payment_cubit.dart';
import 'components/payment_stats_card.dart';
import 'components/remaining_balance_card.dart';
import 'components/student_search_section.dart';
import 'components/transaction_tile.dart';

@RoutePage()
class PaymentListScreen extends StatefulWidget {
  final int? studentId;
  const PaymentListScreen({super.key, @QueryParam('studentId') this.studentId});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  bool _isFiltering = false;
  Map<String, Object?>? _selectedStudent;

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().loadStudents();
    // Auto-select student if navigated with a studentId
    if (widget.studentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final student = await context.read<StudentCubit>().getStudentById(
          widget.studentId!,
        );
        if (student != null && mounted) {
          setState(() => _selectedStudent = student);
          context.read<PaymentCubit>().loadPayments(widget.studentId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
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
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : null,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            children: [
              if (_selectedStudent == null)
                Expanded(
                  child: StudentSearchSection(
                    searchController: _searchController,
                    onStudentSelected: (s) =>
                        setState(() => _selectedStudent = s),
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
                      Map<String, double> monthlyPaid = {};
                      double totalPaid = 0;
                      for (Map<String, Object?> p in state.payments) {
                        final key = "${p['month']}-${p['year']}";
                        monthlyDue[key] = (p['total_amount'] as num).toDouble();
                        monthlyPaid[key] =
                            (monthlyPaid[key] ?? 0) +
                            (p['paid_amount'] as num).toDouble();
                        totalPaid += (p['paid_amount'] as num).toDouble();
                      }
                      double totalDue = monthlyDue.values.fold(
                        0.0,
                        (sum, val) => sum + val,
                      );
                      double remaining = totalDue - totalPaid;
                      if (remaining < 0) remaining = 0;

                      final List<Map<String, dynamic>>
                      filteredPayments = state.payments.where((p) {
                        if (!_isFiltering ||
                            _filterController.text.trim().isEmpty) {
                          return true;
                        }
                        final query = _filterController.text
                            .toLowerCase()
                            .trim();
                        // Searching transaction ID, Description, Amount, etc.
                        final desc =
                            '#TRX-${p['id']} - ${LocaleKeys.semester_fee.tr(args: ['${p['month']}/${p['year']}'])}'
                                .toLowerCase();
                        final amount = p['total_amount'].toString();
                        final paid = p['paid_amount'].toString();
                        return desc.contains(query) ||
                            amount.contains(query) ||
                            paid.contains(query) ||
                            p['month'].toString() == query ||
                            p['year'].toString() == query;
                      }).toList();

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
                              // Header Area
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedStudent!['name']
                                                  as String? ??
                                              'N/A',
                                          style: textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          LocaleKeys.total_payments.tr(
                                            args: [
                                              NumberFormat(
                                                '#,##0',
                                              ).format(totalPaid),
                                              NumberFormat(
                                                '#,##0',
                                              ).format(totalDue),
                                            ],
                                          ),
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedStudent!['student_status'] !=
                                      'free')
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddPaymentDialog(context),
                                      icon: const Icon(Icons.add),
                                      label: Text('إضافة سجل'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 12.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            100.r,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                    ),
                                  SizedBox(width: 8.w),
                                  IconButton.filledTonal(
                                    icon: Icon(
                                      Icons.close,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () =>
                                        setState(() => _selectedStudent = null),
                                    style: IconButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 32.h),

                              if (_selectedStudent!['student_status'] ==
                                  'free') ...[
                                Container(
                                  padding: EdgeInsets.all(24.r),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(24.r),
                                    border: Border.all(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error.withValues(
                                            alpha: 0.2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: colorScheme.error,
                                          size: 28.r,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Text(
                                          LocaleKeys
                                              .payment_disabled_free_student
                                              .tr(),
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onErrorContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                              ],

                              // Bento Grid Style
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 800) {
                                    return IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: PaymentStatsCard(
                                              progress: progress,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: RemainingBalanceCard(
                                              remaining: remaining,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        PaymentStatsCard(progress: progress),
                                        SizedBox(height: 16.h),
                                        RemainingBalanceCard(
                                          remaining: remaining,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              SizedBox(height: 32.h),

                              // Transactions List Container
                              Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(24.r),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            LocaleKeys.transaction_record.tr(),
                                            style: textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                          ),
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              setState(() {
                                                _isFiltering = !_isFiltering;
                                                if (!_isFiltering) {
                                                  _filterController.clear();
                                                }
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.filter_list,
                                              size: 18,
                                            ),
                                            label: const Text('تصفية'),
                                            style: FilledButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      100.r,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isFiltering)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ).copyWith(bottom: 16.h),
                                        child: TextField(
                                          controller: _filterController,
                                          onChanged: (v) => setState(() {}),
                                          decoration: InputDecoration(
                                            hintText:
                                                'ابحث بالرقم، الشهر، السنة، أو المبلغ...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 12.h,
                                                ),
                                          ),
                                        ),
                                      ),
                                    Divider(
                                      height: 1,
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                    if (state.payments.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(48.r),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: 48.r,
                                              color: colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.4),
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              LocaleKeys.no_transactions.tr(),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      LayoutBuilder(
                                        builder: (ctx, constraints) => SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: constraints.maxWidth > 800
                                                ? constraints.maxWidth
                                                : 800,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // Table Header
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                    vertical: 16.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: colorScheme
                                                            .outlineVariant
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'التاريخ / الشهر',
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          'الوصف',
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'المبلغ',
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'الحالة',
                                                          style: textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 48.w,
                                                      ), // actions spacing
                                                    ],
                                                  ),
                                                ),
                                                if (filteredPayments.isEmpty)
                                                  Padding(
                                                    padding: EdgeInsets.all(
                                                      32.r,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'لا توجد عمليات تطابق البحث.',
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemCount:
                                                        filteredPayments.length,
                                                    itemBuilder: (context, i) {
                                                      final p =
                                                          filteredPayments[i];
                                                      final key =
                                                          "${p['month']}-${p['year']}";
                                                      final isMonthPaid =
                                                          (monthlyPaid[key] ??
                                                              0) >=
                                                          (monthlyDue[key] ??
                                                              0);
                                                      return TransactionTile(
                                                        payment: p,
                                                        isFullyPaidMonth:
                                                            isMonthPaid,
                                                        onTap: () =>
                                                            _showEditPaymentDialog(
                                                              context,
                                                              p,
                                                            ),
                                                        onDelete: () {
                                                          _showDeleteDialog(
                                                            context,
                                                            p,
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 48.h),
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
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          LocaleKeys.delete.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this payment record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<PaymentCubit>().deletePayment(
                payment['id'] as int,
                _selectedStudent!['id'] as int,
              );
              Navigator.pop(ctx);
            },
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
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
          final monthlyResults = findMonthlyPayments(
            selectedMonth,
            selectedYear,
          );
          final bool exists = monthlyResults.isNotEmpty;
          final double existingTotal = exists
              ? (monthlyResults.first['total_amount'] as num).toDouble()
              : 0.0;
          final double existingPaid = monthlyResults.fold(
            0.0,
            (sum, p) => sum + (p['paid_amount'] as num).toDouble(),
          );
          final bool isFullyPaid = exists && existingPaid >= existingTotal;
          final colorScheme = Theme.of(ctx).colorScheme;
          final textTheme = Theme.of(ctx).textTheme;

          final defaultInputDeco = InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.all(24.r),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  40.r,
                ), // like HTML rounded-full
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'سجل معاملة جديدة',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh,
                              padding: EdgeInsets.all(12.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),

                    // Body
                    Padding(
                      padding: EdgeInsets.all(40.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الشهر',
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    DropdownButtonFormField<int>(
                                      initialValue: selectedMonth,
                                      isExpanded: true,
                                      decoration: defaultInputDeco,
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
                                          updateControllers(
                                            selectedMonth,
                                            selectedYear,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'السنة',
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    DropdownButtonFormField<int>(
                                      initialValue: selectedYear,
                                      isExpanded: true,
                                      decoration: defaultInputDeco,
                                      items: List.generate(
                                        5,
                                        (int i) => DropdownMenuItem<int>(
                                          value: DateTime.now().year + i - 1,
                                          child: Text(
                                            '${DateTime.now().year + i - 1}',
                                          ),
                                        ),
                                      ),
                                      onChanged: (int? v) {
                                        setDialogState(() {
                                          selectedYear = v!;
                                          errorMessage = null;
                                          updateControllers(
                                            selectedMonth,
                                            selectedYear,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          if (exists) ...[
                            Container(
                              padding: EdgeInsets.all(20.r),
                              decoration: BoxDecoration(
                                color: isFullyPaid
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isFullyPaid
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isFullyPaid
                                            ? Icons.check_circle
                                            : Icons.warning_amber_rounded,
                                        color: isFullyPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 20.r,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        isFullyPaid
                                            ? 'Month Completed'
                                            : 'Existing Payment Found',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isFullyPaid
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'Total: ${LocaleKeys.currency_symbol.tr()} ${existingTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Paid: ${LocaleKeys.currency_symbol.tr()} ${existingPaid.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                          ],

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.total_amount.tr(),
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: exists
                                      ? colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: totalController,
                                readOnly: exists,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                decoration: defaultInputDeco.copyWith(
                                  hintText: '0.00',
                                  prefixIcon: const Icon(
                                    Icons.payments_outlined,
                                  ),
                                  suffixIcon: exists
                                      ? Tooltip(
                                          message: LocaleKeys.total_lock_tooltip
                                              .tr(),
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: exists
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.surfaceContainerHigh,
                                ),
                              ),
                              if (exists)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 6.h,
                                    right: 4.w,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 13,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        LocaleKeys.uses_prev_month_total.tr(),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          if (isFullyPaid)
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 20.r,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      'Month already paid',
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المبلغ المدفوع (${LocaleKeys.currency_symbol.tr()}) الإضافي',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: paidController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  decoration: defaultInputDeco.copyWith(
                                    errorText: errorMessage,
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.payment),
                                    helperText: exists
                                        ? 'Remaining: ${LocaleKeys.currency_symbol.tr()} ${(existingTotal - existingPaid).clamp(0.0, double.infinity).toStringAsFixed(2)}'
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                          SizedBox(height: 48.h),

                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: isFullyPaid
                                      ? null
                                      : () {
                                          final total =
                                              double.tryParse(
                                                totalController.text,
                                              ) ??
                                              0;
                                          final paid =
                                              double.tryParse(
                                                paidController.text,
                                              ) ??
                                              0;

                                          if (total > 0) {
                                            if ((existingPaid + paid) > total) {
                                              setDialogState(() {
                                                errorMessage = LocaleKeys
                                                    .cannot_pay_more_than_total
                                                    .tr();
                                              });
                                              return;
                                            }

                                            context
                                                .read<PaymentCubit>()
                                                .addPaymentTransaction(
                                                  studentId:
                                                      _selectedStudent!['id']
                                                          as int,
                                                  month: selectedMonth,
                                                  year: selectedYear,
                                                  totalAmount: total,
                                                  paidAmount: paid,
                                                );
                                            Navigator.pop(ctx);
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'حفظ العملية',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          final colorScheme = Theme.of(ctx).colorScheme;
          final textTheme = Theme.of(ctx).textTheme;

          final defaultInputDeco = InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.all(24.r),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'تعديل المعاملة',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh,
                              padding: EdgeInsets.all(12.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),

                    // Body
                    Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: colorScheme.primary,
                                  size: 20.r,
                                ),
                                SizedBox(width: 12.w),
                                Flexible(
                                  child: Text(
                                    LocaleKeys.semester_fee.tr(
                                      args: [
                                        '${payment['month']}/${payment['year']}',
                                      ],
                                    ),
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.total_amount.tr(),
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: totalController,
                                readOnly: true,
                                decoration: defaultInputDeco.copyWith(
                                  hintText: '0.00',
                                  prefixIcon: const Icon(
                                    Icons.payments_outlined,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.lock_outline,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${LocaleKeys.paid_amount.tr()} (${LocaleKeys.currency_symbol.tr()})',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: paidController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setDialogState(() => errorMessage = null);
                                  }
                                },
                                decoration: defaultInputDeco.copyWith(
                                  errorText: errorMessage,
                                  hintText: '0.00',
                                  prefixIcon: const Icon(Icons.payment),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 48.h),

                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    final total =
                                        double.tryParse(totalController.text) ??
                                        0;
                                    final paid =
                                        double.tryParse(paidController.text) ??
                                        0;

                                    if (total > 0 && paid >= 0) {
                                      if (paid > total) {
                                        setDialogState(() {
                                          errorMessage = LocaleKeys
                                              .cannot_pay_more_than_total
                                              .tr();
                                        });
                                        return;
                                      }

                                      context
                                          .read<PaymentCubit>()
                                          .updatePayment(paymentId, {
                                            'total_amount': total,
                                            'paid_amount': paid,
                                            'student_id':
                                                _selectedStudent!['id'],
                                          });
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'حفظ التعديلات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
