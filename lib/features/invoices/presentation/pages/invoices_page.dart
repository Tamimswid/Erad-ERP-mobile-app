import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_pagination_list.dart';
import '../../../../core/widgets/date_filter_sheet.dart';
import '../bloc/invoice_cubit.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_empty_state_widget.dart';
import 'invoice_detail_page.dart';
import 'create_invoice_page.dart';

class InvoicesPage extends StatefulWidget {
  final bool isLocal;

  const InvoicesPage({super.key, this.isLocal = false});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<InvoiceCubit>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDateFilter(BuildContext context) {
    final cubit = context.read<InvoiceCubit>();
    final availableYears = _getAvailableYears();
    final hasDateRange = cubit.dateFrom != null && cubit.dateTo != null;

    DateFilterSheet.show(
      context: context,
      selectedYear: null,
      availableYears: availableYears,
      customDateRange: hasDateRange
          ? DateTimeRange(start: cubit.dateFrom!, end: cubit.dateTo!)
          : null,
      isCustomDateRange: hasDateRange,
      onYearSelected: (year) {
        final start = DateTime(int.parse(year), 1, 1);
        final end = DateTime(int.parse(year), 12, 31);
        cubit.setDateRange(start, end);
      },
      onDateRangeSelected: (range) {
        cubit.setDateRange(range.start, range.end);
      },
      onClearFilter: () {
        cubit.setDateRange(null, null);
      },
      onDateRangePickerTap: () async {
        final initial = hasDateRange
            ? DateTimeRange(start: cubit.dateFrom!, end: cubit.dateTo!)
            : DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              );
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: initial,
          builder: (context, child) => child!,
        );
        if (picked != null && context.mounted) {
          cubit.setDateRange(picked.start, picked.end);
          Navigator.pop(context);
        }
      },
    );
  }

  List<String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) => (currentYear - i).toString());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoiceCubit>();
    final hasDateFilter = cubit.dateFrom != null && cubit.dateTo != null;
    final dateLabel = hasDateFilter
        ? '${cubit.dateFrom!.day}/${cubit.dateFrom!.month} - ${cubit.dateTo!.day}/${cubit.dateTo!.month}'
        : 'السنة';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _showDateFilter(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    sc.LucideIcons.calendar,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    sc.LucideIcons.chevronDown,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.isLocal
          ? null
          : FloatingActionButton.extended(
              label: const Text(
                'إضافة فاتورة جديدة',
                style: TextStyle(color: AppColors.onPrimary),
              ),
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInvoicePage(),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<InvoiceCubit>().loadFirstPage();
                  }
                });
              },
            ),
      body: BlocConsumer<InvoiceCubit, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sc.LucideIcons.circleAlert,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: () =>
                        context.read<InvoiceCubit>().getAllInvoices(),
                    child: const Text('حاول ثانية'),
                  ),
                ],
              ),
            );
          }

          if (state is InvoiceFiltered) {
            final allInvoices = <dynamic>[];
            allInvoices.addAll(state.salesInvoices);
            allInvoices.addAll(state.purchaseInvoices);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildFilterSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (allInvoices.isEmpty)
                  const SliverFillRemaining(child: InvoiceEmptyStateWidget())
                else
                  AppPaginationSliverList(
                    itemCount: allInvoices.length,
                    hasMore: state.hasMore,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: context.read<InvoiceCubit>().loadMore,
                    itemBuilder: (context, index) {
                      final invoice = allInvoices[index];
                      final type =
                          invoice.runtimeType.toString().contains('Sales')
                          ? 'sale'
                          : 'purchase';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InvoiceCardWidget(
                          invoice: invoice,
                          type: type,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailPage(
                                  invoiceId: invoice.id,
                                  type: type,
                                ),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<InvoiceCubit>().loadFirstPage();
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث عن فاتورة أو عميل أو مورد...',
        hintStyle: const TextStyle(fontSize: 14),
        prefixIcon: const Icon(sc.LucideIcons.search, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildFilterSection() {
    return sc.Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'النوع',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildChipRow(
            items: [
              // _ChipData('الكل', 'all'),
              _ChipData('بيع', 'sale'),
              _ChipData('شراء', 'purchase'),
            ],
            selected: context.read<InvoiceCubit>().selectedType,
            onTap: (v) => context.read<InvoiceCubit>().setTypeFilter(v),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              'حالة الدفع',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildChipRow(
            items: [
              _ChipData('الكل', 'all'),
              _ChipData('دين', 'debt'),
              _ChipData('نقدي', 'cash'),
            ],
            selected: context.read<InvoiceCubit>().selectedStatus,
            onTap: (v) => context.read<InvoiceCubit>().setStatusFilter(v),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow({
    required List<_ChipData> items,
    required String selected,
    required ValueChanged<String> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: items.last == item ? 0 : 3),
              child: InkWell(
                onTap: () => onTap(item.value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final String value;
  const _ChipData(this.label, this.value);
}
