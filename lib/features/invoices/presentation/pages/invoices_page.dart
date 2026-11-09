import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/notifications/data_change_notifier.dart';
import '../../../../core/widgets/app_pagination_list.dart';
import '../../data/models/invoice_list_filter.dart';
import '../bloc/invoice_cubit.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_empty_state_widget.dart';
import '../widgets/invoice_filter_button.dart';
import '../widgets/invoice_filter_sheet.dart';
import 'create_invoice_page.dart';
import 'invoice_detail_page.dart';

class InvoicesPage extends StatefulWidget {
  final bool isLocal;

  const InvoicesPage({super.key, this.isLocal = false});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();
  final DataChangeNotifier _dataChanges = sl.sl<DataChangeNotifier>();
  late int _invoicesVersion;
  bool _reloadScheduled = false;

  @override
  void initState() {
    super.initState();
    _invoicesVersion = _dataChanges.versionOf(DataDomain.invoices);
    _dataChanges.addListener(_handleDataChange);
    _searchController.addListener(() {
      context.read<InvoiceCubit>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _dataChanges.removeListener(_handleDataChange);
    _searchController.dispose();
    super.dispose();
  }

  void _handleDataChange() {
    if (!mounted) return;
    final version = _dataChanges.versionOf(DataDomain.invoices);
    if (version == _invoicesVersion) return;
    _invoicesVersion = version;
    if (_reloadScheduled) return;

    _reloadScheduled = true;
    Future.microtask(() {
      _reloadScheduled = false;
      if (!mounted) return;
      context.read<InvoiceCubit>().loadFirstPage(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير'), centerTitle: true),
      floatingActionButton: widget.isLocal
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                label: const Text('إضافة فاتورة جديدة', style: TextStyle(color: AppColors.onPrimary)),
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateInvoicePage()));
                },
              ),
            ),
      body: BlocConsumer<InvoiceCubit, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
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
                  Icon(sc.LucideIcons.circleAlert, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  sc.Button(
                    alignment: Alignment.center,
                    style: sc.ButtonStyle.primary(),
                    onPressed: () => context.read<InvoiceCubit>().getAllInvoices(),
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
                        _buildSearchRow(state.filter),
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
                      final type = invoice.runtimeType.toString().contains('Sales') ? 'sale' : 'purchase';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InvoiceCardWidget(
                          invoice: invoice,
                          type: type,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailPage(invoiceId: invoice.id, type: type),
                              ),
                            );
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

  Future<void> _showFilterSheet(BuildContext context) async {
    final cubit = context.read<InvoiceCubit>();
    final filter = await InvoiceFilterSheet.show(context, initialFilter: cubit.listFilter);
    // الورقة قد تفقد صفحة الفواتير أثناء الكتابة (فتح لوحة المفاتيح يعيد بناء
    // الشجرة)، لكن الكيوبت يبقى حياً لذا نطبّق الفلتر عليه مباشرة.
    if (filter == null || cubit.isClosed) return;
    cubit.applyListFilter(filter);
  }

  Widget _buildSearchRow(InvoiceListFilter filter) {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 10),
        InvoiceFilterButton(activeCount: filter.activeCount, onTap: () => _showFilterSheet(context)),
      ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'النوع',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ),
        _buildChipRow(
          items: const [_ChipData('بيع', 'sale'), _ChipData('شراء', 'purchase')],
          selected: context.read<InvoiceCubit>().selectedType,
          onTap: (v) => context.read<InvoiceCubit>().setTypeFilter(v),
        ),
      ],
    );
  }

  Widget _buildChipRow({
    required List<_ChipData> items,
    required String selected,
    required ValueChanged<String> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(10)),
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
                      color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
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
