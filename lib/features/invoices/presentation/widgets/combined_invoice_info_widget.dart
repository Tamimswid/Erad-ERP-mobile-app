import 'dart:async';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/suppliers/presentation/bloc/supplier_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class CombinedInvoiceInfoWidget extends StatefulWidget {
  final FocusNode partySearchFocusNode;
  final VoidCallback onPartySelected;

  const CombinedInvoiceInfoWidget({
    super.key,
    required this.partySearchFocusNode,
    required this.onPartySelected,
  });

  @override
  State<CombinedInvoiceInfoWidget> createState() =>
      _CombinedInvoiceInfoWidgetState();
}

class _CombinedInvoiceInfoWidgetState extends State<CombinedInvoiceInfoWidget> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _isSearching = false;
  dynamic _selectedEntity;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSale => context.read<InvoiceCubit>().invoiceType == 'sale';

  void _focusPartySearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.partySearchFocusNode.requestFocus();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _query = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _query = query;
      _isSearching = true;
    });

    _debounce = Timer(_searchDebounce, () async {
      if (!mounted) return;
      if (_isSale) {
        await context.read<CustomerCubit>().searchCustomers(query);
      } else {
        await context.read<SupplierCubit>().searchSuppliers(query);
      }
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _isSearching = false);
    });
  }

  List<dynamic> get _searchResults {
    if (_query.isEmpty) return const [];

    if (_isSale) {
      final state = context.read<CustomerCubit>().state;
      if (state is! CustomerLoaded) return const [];
      return state.customers.take(10).toList();
    }

    final state = context.read<SupplierCubit>().state;
    if (state is! SuppliersLoaded) return const [];
    return state.suppliers.take(10).toList();
  }

  void _onEntitySelected(dynamic entity) {
    final cubit = context.read<InvoiceCubit>();
    setState(() {
      _selectedEntity = entity;
      _query = '';
      _isSearching = false;
    });
    _searchController.clear();
    widget.partySearchFocusNode.unfocus();

    if (_isSale) {
      cubit.setCustomer(entity.id);
    } else {
      cubit.setSupplier(entity.id);
    }
    widget.onPartySelected();
  }

  void _clearSelection({bool focus = true}) {
    final cubit = context.read<InvoiceCubit>();
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _query = '';
      _isSearching = false;
    });
    if (_isSale) {
      cubit.setCustomer(null);
    } else {
      cubit.setSupplier(null);
    }
    if (focus) {
      _focusPartySearch();
    }
  }

  void _onInvoiceTypeChanged(String type) {
    final cubit = context.read<InvoiceCubit>();
    if (cubit.invoiceType == type) return;
    cubit.setInvoiceType(type);
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _query = '';
      _isSearching = false;
    });
    _focusPartySearch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listenWhen: (previous, current) =>
          current is InvoiceFormUpdated && current.updateType == 'clearAll',
      listener: (context, state) {
        _clearSelection(focus: false);
        _focusPartySearch();
      },
      child: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          final isSale = context.read<InvoiceCubit>().invoiceType == 'sale';

          return sc.Card(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPeriodSelector<String>(
                  expanded: true,
                  options: const [
                    AppPeriodOption(value: 'sale', label: 'بيع'),
                    AppPeriodOption(value: 'purchase', label: 'شراء'),
                  ],
                  selected: isSale ? 'sale' : 'purchase',
                  onChanged: _onInvoiceTypeChanged,
                ),
                const SizedBox(height: 16),
                if (_selectedEntity == null)
                  _buildPartySearch(isSale)
                else
                  _buildSelectedParty(isSale),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartySearch(bool isSale) {
    final results = _searchResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: widget.partySearchFocusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: isSale
                ? 'ابحث عن عميل بالاسم أو الهاتف'
                : 'ابحث عن مورد بالاسم أو الهاتف',
            prefixIcon: const Icon(
              sc.LucideIcons.search,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: _onSearchChanged,
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entity = results[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSale ? sc.LucideIcons.user : sc.LucideIcons.building2,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    entity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: entity.phone != null
                      ? Text(
                          entity.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                  trailing: const Icon(
                    sc.LucideIcons.chevronLeft,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  onTap: () => _onEntitySelected(entity),
                );
              },
            ),
          ),
        ] else if (_query.isNotEmpty && !_isSearching) ...[
          const SizedBox(height: 10),
          Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedParty(bool isSale) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          ),
          child: Icon(
            isSale ? sc.LucideIcons.user : sc.LucideIcons.building2,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedEntity.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              if (_selectedEntity.phone != null)
                Text(
                  _selectedEntity.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        sc.Button(
          alignment: Alignment.center,
          style: sc.ButtonStyle.ghost(),
          onPressed: () => _clearSelection(),
          leading: const Icon(sc.LucideIcons.x, size: 16),
          child: const Text('تغيير'),
        ),
      ],
    );
  }
}
