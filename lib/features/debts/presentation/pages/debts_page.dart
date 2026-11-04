import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/presentation/bloc/customer_debt_cubit.dart';
import 'package:erad/features/customer_debts/presentation/pages/customer_detail_page.dart';
import 'package:erad/features/debts/presentation/debts_types.dart';
import 'package:erad/features/debts/presentation/widgets/debt_party_card.dart';
import 'package:erad/features/debts/presentation/widgets/debts_search_field.dart';
import 'package:erad/features/debts/presentation/widgets/debts_status_views.dart';
import 'package:erad/features/debts/presentation/widgets/debts_summary_card.dart';
import 'package:erad/features/debts/presentation/widgets/payment_modal_widget.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/presentation/bloc/supplier_debt_cubit.dart';
import 'package:erad/features/suppliers_debts/presentation/pages/supplier_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class DebtsPage extends StatefulWidget {
  final bool isLocal;

  const DebtsPage({super.key, this.isLocal = false});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  DebtsParty _party = DebtsParty.customers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الديون')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: AppPeriodSelector<DebtsParty>(
              expanded: true,
              options: const [
                AppPeriodOption(value: DebtsParty.customers, label: 'العملاء'),
                AppPeriodOption(value: DebtsParty.suppliers, label: 'الموردون'),
              ],
              selected: _party,
              onChanged: (party) => setState(() => _party = party),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _party.index,
              children: [
                _CustomerDebtsTab(isLocal: widget.isLocal),
                _SupplierDebtsTab(isLocal: widget.isLocal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDebtsTab extends StatelessWidget {
  final bool isLocal;

  const _CustomerDebtsTab({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl.sl<CustomerDebtCubit>()..getCustomerDebts(),
      child: _CustomerDebtsView(isLocal: isLocal),
    );
  }
}

class _CustomerDebtsView extends StatelessWidget {
  final bool isLocal;

  const _CustomerDebtsView({required this.isLocal});

  void _openDetails(BuildContext context, CustomerDebtModel debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: debt, isLocal: isLocal),
      ),
    );
  }

  void _openPayment(BuildContext context, CustomerDebtModel debt) {
    showDialog(
      context: context,
      builder: (_) => PaymentModalWidget(
        remainingDebt: debt.remainingDebt,
        onPaymentSubmit: (amount, date, note) {
          Navigator.pop(context);
          context.read<CustomerDebtCubit>().addPayment(
            debt.id,
            amount,
            note,
            date,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerDebtCubit, CustomerDebtState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is CustomerDebtInitial || state is CustomerDebtLoading) {
          return const DebtsLoadingView();
        }
        if (state is CustomerDebtError) {
          return DebtsErrorView(
            message: state.message,
            onRetry: () => context.read<CustomerDebtCubit>().getCustomerDebts(),
          );
        }

        final cubit = context.read<CustomerDebtCubit>();
        final loaded = state is CustomerDebtLoaded ? state : null;
        final debts = cubit.debtsWithDebt;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DebtsSummaryCard(
                      title: 'إجمالي ديون العملاء',
                      totalDebt: cubit.totalDebt,
                      totalInvoices: cubit.totalInvoices,
                      totalPaid: cubit.totalPaid,
                      partyCount: loaded?.debtorCount ?? cubit.debtorCount,
                    ),
                    const SizedBox(height: 16),
                    DebtsSearchField(
                      hint: 'البحث عن عميل بالاسم أو الهاتف...',
                      onChanged: cubit.searchCustomerDebts,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (debts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: DebtsEmptyView(
                  title: 'لا توجد ديون مستحقة',
                  subtitle: 'تم سداد جميع الفواتير أو لا توجد نتائج مطابقة',
                ),
              )
            else
              AppPaginationSliverList(
                itemCount: debts.length,
                hasMore: loaded?.hasMore ?? cubit.hasMore,
                isLoadingMore: loaded?.isLoadingMore ?? cubit.isLoadingMore,
                onLoadMore: cubit.loadMore,
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return DebtPartyCard(
                    name: debt.name,
                    phone: debt.phone,
                    totalInvoices: debt.totalInvoices,
                    totalPaid: debt.totalPaid,
                    remainingDebt: debt.remainingDebt,
                    invoiceCount: debt.totalInvoicesCount,
                    pendingCount: debt.pendingInvoicesCount,
                    overdueCount: debt.overdueInvoicesCount,
                    latestDueDate: debt.latestDueDate,
                    onTap: () => _openDetails(context, debt),
                    onPaymentTap: isLocal
                        ? null
                        : () => _openPayment(context, debt),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SupplierDebtsTab extends StatelessWidget {
  final bool isLocal;

  const _SupplierDebtsTab({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl.sl<SupplierDebtCubit>()..getSupplierDebts(),
      child: _SupplierDebtsView(isLocal: isLocal),
    );
  }
}

class _SupplierDebtsView extends StatelessWidget {
  final bool isLocal;

  const _SupplierDebtsView({required this.isLocal});

  void _openDetails(BuildContext context, SupplierDebtModel debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailPage(supplier: debt, isLocal: isLocal),
      ),
    );
  }

  void _openPayment(BuildContext context, SupplierDebtModel debt) {
    showDialog(
      context: context,
      builder: (_) => PaymentModalWidget(
        remainingDebt: debt.remainingDebt,
        onPaymentSubmit: (amount, date, note) {
          Navigator.pop(context);
          context.read<SupplierDebtCubit>().addPayment(
            debt.id,
            amount,
            note,
            date,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierDebtCubit, SupplierDebtState>(
      listener: (context, state) {
        if (state is SupplierPaymentSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is SupplierDebtInitial || state is SupplierDebtLoading) {
          return const DebtsLoadingView();
        }
        if (state is SupplierDebtError) {
          return DebtsErrorView(
            message: state.message,
            onRetry: () => context.read<SupplierDebtCubit>().getSupplierDebts(),
          );
        }

        final cubit = context.read<SupplierDebtCubit>();
        final loaded = state is SupplierDebtLoaded ? state : null;
        final debts = cubit.debtsWithDebt;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DebtsSummaryCard(
                      title: 'إجمالي ديون الموردين',
                      totalDebt: cubit.totalDebt,
                      totalInvoices: cubit.totalInvoices,
                      totalPaid: cubit.totalPaid,
                      partyCount: loaded?.debtorCount ?? cubit.debtorCount,
                      countIcon: sc.LucideIcons.truck,
                    ),
                    const SizedBox(height: 16),
                    DebtsSearchField(
                      hint: 'البحث عن مورد بالاسم أو الهاتف...',
                      onChanged: cubit.searchSupplierDebts,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (debts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: DebtsEmptyView(
                  title: 'لا توجد ديون مستحقة',
                  subtitle: 'تم سداد جميع الفواتير أو لا توجد نتائج مطابقة',
                ),
              )
            else
              AppPaginationSliverList(
                itemCount: debts.length,
                hasMore: loaded?.hasMore ?? cubit.hasMore,
                isLoadingMore: loaded?.isLoadingMore ?? cubit.isLoadingMore,
                onLoadMore: cubit.loadMore,
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return DebtPartyCard(
                    name: debt.name,
                    phone: debt.phone,
                    totalInvoices: debt.totalInvoices,
                    totalPaid: debt.totalPaid,
                    remainingDebt: debt.remainingDebt,
                    invoiceCount: debt.totalInvoicesCount,
                    pendingCount: debt.pendingInvoicesCount,
                    overdueCount: debt.overdueInvoicesCount,
                    latestDueDate: debt.latestDueDate,
                    onTap: () => _openDetails(context, debt),
                    onPaymentTap: isLocal
                        ? null
                        : () => _openPayment(context, debt),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
