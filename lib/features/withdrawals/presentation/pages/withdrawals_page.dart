import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/widgets/date_filter_sheet.dart';
import '../../data/models/partner.dart';
import '../bloc/withdrawal_cubit.dart';
import '../widgets/summary_cards_widget.dart';
import '../widgets/monthly_chart_widget.dart';
import '../widgets/withdrawals_table_widget.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_withdrawal_dialog.dart';

class WithdrawalsPage extends StatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  State<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends State<WithdrawalsPage> {
  String? _selectedYear = DateTime.now().year.toString();
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl.sl<WithdrawalCubit>(),
      child: _WithdrawalsPageBody(
        selectedYear: _selectedYear,
        customDateRange: _customDateRange,
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onCustomDateRangeChanged: (range) =>
            setState(() => _customDateRange = range),
        onClearCustomDateRange: () => setState(() => _customDateRange = null),
        availableYears: [
          DateTime.now().year.toString(),
          (DateTime.now().year - 1).toString(),
          (DateTime.now().year - 2).toString(),
        ],
      ),
    );
  }
}

class _WithdrawalsPageBody extends StatefulWidget {
  final String? selectedYear;
  final DateTimeRange? customDateRange;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final VoidCallback onClearCustomDateRange;
  final List<String> availableYears;

  const _WithdrawalsPageBody({
    required this.selectedYear,
    required this.customDateRange,
    required this.onYearChanged,
    required this.onCustomDateRangeChanged,
    required this.onClearCustomDateRange,
    required this.availableYears,
  });

  @override
  State<_WithdrawalsPageBody> createState() => _WithdrawalsPageBodyState();
}

class _WithdrawalsPageBodyState extends State<_WithdrawalsPageBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year =
          int.tryParse(widget.selectedYear ?? DateTime.now().year.toString()) ??
          DateTime.now().year;
      context.read<WithdrawalCubit>().filterByYear(year.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السحوبات'),
        backgroundColor: AppColors.background,
        actions: [  Builder(
            builder: (context) {
              final cubit = context.read<WithdrawalCubit>();
              final state = cubit.state;
              final hasPartners = state is WithdrawalsLoaded && state.partners.isNotEmpty;
              return hasPartners 
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () => _showAddPartnerDialog(context),
                        icon: const Icon(Icons.person_add_alt_1, size: 22),
                        tooltip: 'إضافة شريك',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _WithdrawalsDateFilter(
              selectedYear: widget.selectedYear,
              customDateRange: widget.customDateRange,
              onYearSelected: (year) {
                widget.onYearChanged(year);
                context.read<WithdrawalCubit>().filterByYear(year);
              },
              onDateRangeSelected: (range) {
                widget.onCustomDateRangeChanged(range);
                context.read<WithdrawalCubit>().filterByDateRange(range.start, range.end);
              },
              onClearFilter: () {
                widget.onClearCustomDateRange();
                final year = widget.selectedYear ?? DateTime.now().year.toString();
                context.read<WithdrawalCubit>().filterByYear(year);
              },
            ),
          ),
        
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<WithdrawalCubit, WithdrawalState>(
          listener: (context, state) {
            if (state is WithdrawalSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is WithdrawalError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WithdrawalInitial || state is WithdrawalLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is WithdrawalsLoaded) ...[
                    if (state.partners.isEmpty)
                      _buildEmptyPartnersState(context)
                    else ...[
                      _buildPartnerSelector(context, state),
                      const SizedBox(height: 12),
                      SummaryCardsWidget(
                        totalAmount: state.totalAmount,
                        totalCount: state.totalCount,
                        averageAmount: state.averageAmount,
                      ),
                      const SizedBox(height: 12),
                      MonthlyChartWidget(monthlyData: state.monthlyData),
                      const SizedBox(height: 12),
                      WithdrawalsTableWidget(
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
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final partners = context.watch<WithdrawalCubit>().state;
          final partnerList = partners is WithdrawalsLoaded 
              ? partners.partners 
              : <Partner>[];
          return FloatingActionButton.extended(
            label: Text('سحب', style: TextStyle(color: AppColors.surface)),
            onPressed: () => _showAddWithdrawalDialog(
              context: context,
              onTap: (withdrawal) {
                context.read<WithdrawalCubit>().createWithdrawal(withdrawal);
              },
              partners: partnerList,
            ),
            backgroundColor: AppColors.primary,
          );
        },
      ),
    );
  }

  Widget _buildEmptyPartnersState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد شركاء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف شريكاً للبدء',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPartnerDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة شريك'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSelector(BuildContext context, WithdrawalsLoaded state) {
    final cubit = context.read<WithdrawalCubit>();
    final selectedId = state.selectedPartnerId;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPartnerChip(
            label: 'الكل',
            isSelected: selectedId == null,
            onTap: () => cubit.filterByPartner(null),
          ),
          const SizedBox(width: 8),
          ...state.partners.map((partner) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPartnerChip(
                label: partner.name,
                isSelected: selectedId == partner.id,
                onTap: () => cubit.filterByPartner(partner.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPartnerChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddUserDialog(
        onSave: (name, phone) {
          final partner = Partner(
            id: '',
            name: name,
            phone: phone.isEmpty ? null : phone,
            createdAt: DateTime.now(),
          );
          context.read<WithdrawalCubit>().createPartner(partner);
        },
      ),
    );
  }

  void _showAddWithdrawalDialog({
    required BuildContext context,
    required Function(dynamic) onTap,
    required List<Partner> partners,
  }) {
    final usersMap = <String, Map<String, dynamic>>{};
    for (final partner in partners) {
      usersMap[partner.id] = {'name': partner.name, 'phone': partner.phone};
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AddWithdrawalDialog(
        users: usersMap,
        onSave: onTap,
      ),
    );
  }
}

class _WithdrawalsDateFilter extends StatelessWidget {
  final String? selectedYear;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onYearSelected;
  final ValueChanged<DateTimeRange> onDateRangeSelected;
  final VoidCallback onClearFilter;

  const _WithdrawalsDateFilter({
    required this.selectedYear,
    required this.customDateRange,
    required this.onYearSelected,
    required this.onDateRangeSelected,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final label = customDateRange != null
        ? '${customDateRange!.start.day}/${customDateRange!.start.month} - ${customDateRange!.end.day}/${customDateRange!.end.month}'
        : (selectedYear ?? DateTime.now().year.toString());

    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final now = DateTime.now();
    final availableYears = [
      now.year.toString(),
      (now.year - 1).toString(),
      (now.year - 2).toString(),
    ];

    DateTimeRange? customDateRangeLocal = customDateRange;

    DateFilterSheet.show(
      context: context,
      selectedYear: selectedYear,
      availableYears: availableYears,
      customDateRange: customDateRangeLocal,
      isCustomDateRange: customDateRangeLocal != null,
      onYearSelected: onYearSelected,
      onDateRangeSelected: onDateRangeSelected,
      onClearFilter: onClearFilter,
      onDateRangePickerTap: () => _pickDateRange(context),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final initial = customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      onDateRangeSelected(picked);
    }
  }
}