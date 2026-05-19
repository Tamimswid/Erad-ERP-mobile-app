import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';

class CombinedInvoiceInfoWidget extends StatefulWidget {
  const CombinedInvoiceInfoWidget({super.key});

  @override
  State<CombinedInvoiceInfoWidget> createState() => _CombinedInvoiceInfoWidgetState();
}

class _CombinedInvoiceInfoWidgetState extends State<CombinedInvoiceInfoWidget> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  dynamic _selectedEntity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';

    // Detect invoice type change and reset selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (isSale) {
          invoiceCubit.setSupplier(null);
        } else {
          invoiceCubit.setCustomer(null);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';

    if (isSale) {
      if (context.read<CustomerCubit>().state is CustomerLoaded) {
        final customers = (context.read<CustomerCubit>().state as CustomerLoaded).customers;
        final results = customers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
                 customer.code.toLowerCase().contains(query.toLowerCase()) ||
                 (customer.phone?.contains(query) ?? false);
        }).toList();

        setState(() {
          _searchResults = results.take(10).toList();
        });
      }
    } else {
      if (context.read<SupplierCubit>().state is SuppliersLoaded) {
        final suppliers = (context.read<SupplierCubit>().state as SuppliersLoaded).suppliers;
        final results = suppliers.where((supplier) {
          return supplier.name.toLowerCase().contains(query.toLowerCase()) ||
                 (supplier.phone?.contains(query) ?? false);
        }).toList();

        setState(() {
          _searchResults = results.take(10).toList();
        });
      }
    }
  }

  void _onEntitySelected(dynamic entity) {
    setState(() {
      _selectedEntity = entity;
      _searchResults = [];
      _searchFocusNode.unfocus();
    });
    _searchController.text = entity.name;
    
    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';
    
    if (isSale) {
      invoiceCubit.setCustomer(entity.id);
    } else {
      invoiceCubit.setSupplier(entity.id);
    }
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
    
    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';
    
    if (isSale) {
      invoiceCubit.setSupplier(null);
    } else {
      invoiceCubit.setCustomer(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final isSale = context.read<InvoiceCubit>().invoiceType == 'sale';
        
        return Card(
          elevation: AppConstants.cardElevation,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
            side: BorderSide(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Type and Payment Type Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _buildInvoiceTypeDropdown(state),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPaymentTypeDropdown(state),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                _buildSearchBar(isSale),
                const SizedBox(height: 16),
                
                // Search Results List
                if (_searchResults.isNotEmpty)
                  _buildSearchResultsList(isSale),
                
                // Selected Entity Display
                if (_selectedEntity != null)
                  _buildSelectedEntityDisplay(isSale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceTypeDropdown(InvoiceState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: context.read<InvoiceCubit>().invoiceType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'sale', child: Text('مبيع')),
            DropdownMenuItem(value: 'purchase', child: Text('شراء')),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<InvoiceCubit>().setInvoiceType(value);
              _clearSelection();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentTypeDropdown(InvoiceState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: context.read<InvoiceCubit>().debtType ?? 'debtor',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'debtor', child: Text('آجل')),
            DropdownMenuItem(value: 'creditor', child: Text('نقدي')),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<InvoiceCubit>().setDebtType(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isSale) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: isSale ? 'ابحث عن عميل...' : 'ابحث عن مورد...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        suffixIcon: _selectedEntity != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSelection,
              )
            : null,
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildSearchResultsList(bool isSale) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        color: AppColors.surface,
        boxShadow: AppConstants.cardShadow,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final entity = _searchResults[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                isSale ? Icons.person : Icons.business,
                color: AppColors.primary,
                size: 20,
              ),
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
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onTap: () => _onEntitySelected(entity),
          );
        },
      ),
    );
  }

  Widget _buildSelectedEntityDisplay(bool isSale) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              isSale ? Icons.person : Icons.business,
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
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _clearSelection,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
