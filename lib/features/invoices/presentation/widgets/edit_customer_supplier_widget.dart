import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditCustomerSupplierWidget extends StatefulWidget {
  final bool isSales;

  const EditCustomerSupplierWidget({super.key, required this.isSales});

  @override
  State<EditCustomerSupplierWidget> createState() =>
      _EditCustomerSupplierWidgetState();
}

class _EditCustomerSupplierWidgetState
    extends State<EditCustomerSupplierWidget> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  dynamic _selectedEntity;
  bool _isInitialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initSelection(EditInvoiceCubit cubit) {
    if (_isInitialized) return;

    if (widget.isSales && cubit.customerId != null) {
      final customerState = context.read<CustomerCubit>().state;
      if (customerState is CustomerLoaded) {
        try {
          final customer = customerState.customers.firstWhere(
            (c) => c.id == cubit.customerId,
          );
          _selectedEntity = customer;
          _searchController.text = customer.name;
          _isInitialized = true;
        } catch (_) {}
      }
    } else if (!widget.isSales && cubit.supplierId != null) {
      final supplierState = context.read<SupplierCubit>().state;
      if (supplierState is SuppliersLoaded) {
        try {
          final supplier = supplierState.suppliers.firstWhere(
            (s) => s.id == cubit.supplierId,
          );
          _selectedEntity = supplier;
          _searchController.text = supplier.name;
          _isInitialized = true;
        } catch (_) {}
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_selectedEntity != null && query != _selectedEntity.name) {
      setState(() {
        _selectedEntity = null;
      });
      if (widget.isSales) {
        context.read<EditInvoiceCubit>().setCustomer(null);
      } else {
        context.read<EditInvoiceCubit>().setSupplier(null);
      }
    }

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (widget.isSales) {
      final customerState = context.read<CustomerCubit>().state;
      if (customerState is CustomerLoaded) {
        final results = customerState.customers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.code.toLowerCase().contains(query.toLowerCase()) ||
              (customer.phone?.contains(query) ?? false);
        }).toList();

        setState(() {
          _searchResults = results.take(10).toList();
        });
      }
    } else {
      final supplierState = context.read<SupplierCubit>().state;
      if (supplierState is SuppliersLoaded) {
        final results = supplierState.suppliers.where((supplier) {
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

    if (widget.isSales) {
      context.read<EditInvoiceCubit>().setCustomer(entity.id);
    } else {
      context.read<EditInvoiceCubit>().setSupplier(entity.id);
    }
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();

    if (widget.isSales) {
      context.read<EditInvoiceCubit>().setCustomer(null);
    } else {
      context.read<EditInvoiceCubit>().setSupplier(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerCubit, CustomerState>(
          listener: (context, state) {
            if (state is CustomerLoaded && mounted) setState(() {});
          },
        ),
        BlocListener<SupplierCubit, SupplierState>(
          listener: (context, state) {
            if (state is SuppliersLoaded && mounted) setState(() {});
          },
        ),
      ],
      child: BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
        builder: (context, state) {
          if (state is EditInvoiceLoaded) {
            _initSelection(context.read<EditInvoiceCubit>());
          }

          final title = widget.isSales ? 'العميل' : 'المورد';
          final hintText = widget.isSales
              ? 'ابحث عن عميل...'
              : 'ابحث عن مورد...';

          return sc.Card(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  widget.isSales
                      ? sc.LucideIcons.user
                      : sc.LucideIcons.building2,
                  title,
                ),
                const SizedBox(height: AppConstants.spacingMd),

                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: Icon(
                      widget.isSales
                          ? sc.LucideIcons.search
                          : sc.LucideIcons.search,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixIcon: _selectedEntity != null
                        ? IconButton(
                            icon: const Icon(sc.LucideIcons.x),
                            onPressed: _clearSelection,
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppConstants.borderRadius),
                        bottomRight: Radius.circular(AppConstants.borderRadius),
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
                            backgroundColor: AppColors.muted,
                            child: Icon(
                              widget.isSales
                                  ? sc.LucideIcons.user
                                  : sc.LucideIcons.building2,
                              color: AppColors.text,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            entity.name,
                            style: const TextStyle(
                              fontWeight: AppFonts.fontWeightMedium,
                              color: AppColors.text,
                            ),
                          ),
                          subtitle: Text(
                            entity.phone ?? '-',
                            style: const TextStyle(
                              fontSize: AppFonts.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => _onEntitySelected(entity),
                        );
                      },
                    ),
                  ),

                if (_selectedEntity != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.muted,
                          child: Icon(
                            widget.isSales
                                ? sc.LucideIcons.user
                                : sc.LucideIcons.building2,
                            color: AppColors.text,
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
                                  fontWeight: AppFonts.fontWeightSemiBold,
                                  color: AppColors.text,
                                ),
                              ),
                              if (_selectedEntity.phone != null)
                                Text(
                                  _selectedEntity.phone ?? '-',
                                  style: const TextStyle(
                                    fontSize: AppFonts.fontSizeSmall,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(sc.LucideIcons.x, size: 20),
                          onPressed: _clearSelection,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
