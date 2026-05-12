import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../data/models/partner.dart';
import '../bloc/withdrawal_cubit.dart';
import '../widgets/header_widget.dart';
import '../widgets/user_selector_widget.dart';
import '../widgets/filters_widget.dart';
import '../widgets/summary_cards_widget.dart';
import '../widgets/monthly_chart_widget.dart';
import '../widgets/view_mode_selector_widget.dart';
import '../widgets/withdrawals_table_widget.dart';
import '../widgets/withdrawals_cards_widget.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_withdrawal_dialog.dart';

class WithdrawalsPage extends StatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  State<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends State<WithdrawalsPage> {
  ViewMode _viewMode = ViewMode.table;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<WithdrawalCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<WithdrawalCubit, WithdrawalState>(
          listener: (context, state) {
            if (state is WithdrawalError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WithdrawalInitial || state is WithdrawalLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final availableYear = DateTime.now().year;
            final availableYears = [
              availableYear.toString(),
              (availableYear + 1).toString(),
              (availableYear + 2).toString(),
              (availableYear + 3).toString(),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is WithdrawalsLoaded) ...[
                    if (state.partners.isEmpty)
                      _buildEmptyPartnersState(context)
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FiltersWidget(
                              periodMode: state.startDate != null
                                  ? PeriodMode.custom
                                  : PeriodMode.year,
                              onPeriodModeChanged: (mode) {
                                if (mode == PeriodMode.year) {
                                  context
                                      .read<WithdrawalCubit>()
                                      .clearFilters();
                                }
                              },

                              selectedYear: DateTime.now().year.toString(),
                              onYearChanged: (year) {},
                              dateFrom: state.startDate,
                              dateTo: state.endDate,
                              onDateFromChanged: (date) => context
                                  .read<WithdrawalCubit>()
                                  .filterByDateRange(date, state.endDate),
                              onDateToChanged: (date) => context
                                  .read<WithdrawalCubit>()
                                  .filterByDateRange(state.startDate, date),
                              availableYears: availableYears,
                            ),
                          ),
                          const SizedBox(width: 16),

                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildPartnerSelector(context, state),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SummaryCardsWidget(
                        totalAmount: state.totalAmount,
                        totalCount: state.totalCount,
                        averageAmount: state.averageAmount,
                      ),
                      const SizedBox(height: 16),
                      MonthlyChartWidget(monthlyData: state.monthlyData),
                      const SizedBox(height: 16),
                      ViewModeSelectorWidget(
                        currentMode: _viewMode,
                        onModeChanged: (mode) =>
                            setState(() => _viewMode = mode),
                      ),
                      const SizedBox(height: 14),
                      if (_viewMode == ViewMode.table)
                        WithdrawalsTableWidget(
                          withdrawals: state.withdrawals,
                          partners: state.partners,
                          onDelete: (withdrawal) => context
                              .read<WithdrawalCubit>()
                              .deleteWithdrawal(withdrawal.id),
                          onTap: (withdrawal) {},
                        )
                      else
                        WithdrawalsCardsWidget(
                          withdrawals: state.withdrawals,
                          partners: state.partners,
                          onDelete: (withdrawal) => context
                              .read<WithdrawalCubit>()
                              .deleteWithdrawal(withdrawal.id),
                          onTap: (withdrawal) {},
                        ),
                    ],
                  ] else if (state is WithdrawalLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final state = context.watch<WithdrawalCubit>().state;
            final partners = state is WithdrawalsLoaded
                ? state.partners
                : <Partner>[];
            if (partners.isEmpty) return const SizedBox.shrink();
            final partnersMap = {
              for (final p in partners)
                p.id: {'id': p.id, 'name': p.name, 'phone': p.phone},
            };
            return FloatingActionButton(
              onPressed: () => _showAddWithdrawalDialog(context, partnersMap),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyPartnersState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد مستخدمين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف مستخدم جديد للبدء',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPartnerDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة مستخدم جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSelector(BuildContext context, WithdrawalsLoaded state) {
    final selectedPartner = state.selectedPartnerId != null
        ? state.partners
              .where((p) => p.id == state.selectedPartnerId)
              .firstOrNull
        : null;

    return UserSelectorWidget(
      selectedPartner: selectedPartner,
      onAddNew: () => _showAddPartnerDialog(context),
      onClearSelection: () =>
          context.read<WithdrawalCubit>().filterByPartner(null),
      partners: state.partners,
      onSelectPartner: (partner) =>
          context.read<WithdrawalCubit>().filterByPartner(partner.id),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    AddUserDialog.show(
      context,
      onSave: (name, phone) {
        final partner = Partner(
          id: '',
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
        );
        context.read<WithdrawalCubit>().createPartner(partner);
      },
    );
  }

  void _showAddWithdrawalDialog(
    BuildContext context,
    Map<String, Map<String, dynamic>> partners,
  ) {
    AddWithdrawalDialog.show(
      context,
      onSave: (withdrawal) =>
          context.read<WithdrawalCubit>().createWithdrawal(withdrawal),
      users: partners,
    );
  }
}
