import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/data/models/supplier.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../bloc/invoice_cubit.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class CustomerSupplierSearchWidget extends StatefulWidget {
  const CustomerSupplierSearchWidget({super.key});

  @override
  State<CustomerSupplierSearchWidget> createState() =>
      _CustomerSupplierSearchWidgetState();
}

class _CustomerSupplierSearchWidgetState
    extends State<CustomerSupplierSearchWidget> {
  String? _previousInvoiceType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final invoiceCubit = context.read<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';

    // Detect invoice type change and reset cubit selection
    if (_previousInvoiceType != null &&
        _previousInvoiceType != invoiceCubit.invoiceType) {
      // Clear the selection when switching between customer/supplier
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
    _previousInvoiceType = invoiceCubit.invoiceType;
  }

  @override
  Widget build(BuildContext context) {
    final invoiceCubit = context.watch<InvoiceCubit>();
    final isSale = invoiceCubit.invoiceType == 'sale';

    if (isSale) {
      return BlocBuilder<CustomerCubit, CustomerState>(
        key: ValueKey('customer-${invoiceCubit.invoiceType}'),
        builder: (context, customerState) {
          return _CustomerSearchContent(
            key: ValueKey('customer-content-${invoiceCubit.invoiceType}'),
            state: customerState,
          );
        },
      );
    } else {
      return BlocBuilder<SupplierCubit, SupplierState>(
        key: ValueKey('supplier-${invoiceCubit.invoiceType}'),
        builder: (context, supplierState) {
          return _SupplierSearchContent(
            key: ValueKey('supplier-content-${invoiceCubit.invoiceType}'),
            state: supplierState,
          );
        },
      );
    }
  }
}

class _CustomerSearchContent extends StatefulWidget {
  final CustomerState state;
  final Key? key;

  const _CustomerSearchContent({required this.state, this.key});

  @override
  State<_CustomerSearchContent> createState() => _CustomerSearchContentState();
}

class _CustomerSearchContentState extends State<_CustomerSearchContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  dynamic _selectedEntity;

  @override
  void didUpdateWidget(_CustomerSearchContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when widget key changes (invoice type switched)
    if (oldWidget.key != widget.key) {
      _searchController.clear();
      setState(() {
        _searchResults = [];
        _selectedEntity = null;
      });
    }
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

    if (widget.state is CustomerLoaded) {
      final customers = (widget.state as CustomerLoaded).customers;
      final results = customers.where((customer) {
        return customer.name.toLowerCase().contains(query.toLowerCase()) ||
            customer.code.toLowerCase().contains(query.toLowerCase()) ||
            (customer.phone?.contains(query) ?? false);
      }).toList();

      setState(() {
        _searchResults = results.take(10).toList();
      });
    }
  }

  void _onEntitySelected(CustomerModel entity) {
    setState(() {
      _selectedEntity = entity;
      _searchResults = [];
      _searchFocusNode.unfocus();
    });
    _searchController.text = entity.name;
    context.read<InvoiceCubit>().setCustomer(entity.id);
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
    context.read<InvoiceCubit>().setCustomer(null);
  }

  @override
  Widget build(BuildContext context) {
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
            _buildSectionTitle(sc.LucideIcons.user, 'العميل'),
            const SizedBox(height: AppConstants.spacingMd),

            if (widget.state is CustomerInitial ||
                widget.state is CustomerLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (widget.state is CustomerError)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      sc.LucideIcons.circleAlert,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (widget.state as CustomerError).message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(sc.LucideIcons.refreshCw, size: 20),
                      onPressed: () {
                        context.read<CustomerCubit>().getCustomers();
                      },
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),

            if (widget.state is CustomerLoaded)
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن عميل...',
                      prefixIcon: const Icon(
                        sc.LucideIcons.search,
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
                  const SizedBox(height: 12),

                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(
                            AppConstants.borderRadius,
                          ),
                          bottomRight: Radius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        color: AppColors.surface,
                        boxShadow: AppConstants.cardShadow,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final customer =
                              _searchResults[index] as CustomerModel;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                sc.LucideIcons.user,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: AppFonts.fontWeightMedium,
                                color: AppColors.text,
                              ),
                            ),
                            subtitle: Text(
                              customer.phone ?? '-',
                              style: const TextStyle(
                                fontSize: AppFonts.fontSizeSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              sc.LucideIcons.chevronLeft,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            onTap: () => _onEntitySelected(customer),
                          );
                        },
                      ),
                    ),
                ],
              ),

            if (_selectedEntity != null && widget.state is CustomerLoaded)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        sc.LucideIcons.user,
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
                              fontWeight: AppFonts.fontWeightSemiBold,
                              color: AppColors.text,
                            ),
                          ),
                          if (_selectedEntity.phone != null)
                            Text(
                              '${_selectedEntity.phone}',
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
                      onPressed: () => _clearSelection(),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        ),
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

class _SupplierSearchContent extends StatefulWidget {
  final SupplierState state;
  final Key? key;

  const _SupplierSearchContent({required this.state, this.key});

  @override
  State<_SupplierSearchContent> createState() => _SupplierSearchContentState();
}

class _SupplierSearchContentState extends State<_SupplierSearchContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  dynamic _selectedEntity;

  @override
  void didUpdateWidget(_SupplierSearchContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when widget key changes (invoice type switched)
    if (oldWidget.key != widget.key) {
      _searchController.clear();
      setState(() {
        _searchResults = [];
        _selectedEntity = null;
      });
    }
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

    if (widget.state is SuppliersLoaded) {
      final suppliers = (widget.state as SuppliersLoaded).suppliers;
      final results = suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(query.toLowerCase()) ||
            (supplier.phone?.contains(query) ?? false);
      }).toList();

      setState(() {
        _searchResults = results.take(10).toList();
      });
    }
  }

  void _onEntitySelected(SupplierModel entity) {
    setState(() {
      _selectedEntity = entity;
      _searchResults = [];
      _searchFocusNode.unfocus();
    });
    _searchController.text = entity.name;
    context.read<InvoiceCubit>().setSupplier(entity.id);
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _selectedEntity = null;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
    context.read<InvoiceCubit>().setSupplier(null);
  }

  @override
  Widget build(BuildContext context) {
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
            _buildSectionTitle(sc.LucideIcons.building2, 'المورد'),
            const SizedBox(height: AppConstants.spacingMd),

            if (widget.state is SupplierInitial ||
                widget.state is SupplierLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (widget.state is SupplierError)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      sc.LucideIcons.circleAlert,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (widget.state as SupplierError).message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(sc.LucideIcons.refreshCw, size: 20),
                      onPressed: () {
                        context.read<SupplierCubit>().getSuppliers();
                      },
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),

            if (widget.state is SuppliersLoaded)
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مورد...',
                      prefixIcon: const Icon(
                        sc.LucideIcons.search,
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
                  const SizedBox(height: 12),

                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(
                            AppConstants.borderRadius,
                          ),
                          bottomRight: Radius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        color: AppColors.surface,
                        boxShadow: AppConstants.cardShadow,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final supplier =
                              _searchResults[index] as SupplierModel;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                sc.LucideIcons.building2,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              supplier.name,
                              style: const TextStyle(
                                fontWeight: AppFonts.fontWeightMedium,
                                color: AppColors.text,
                              ),
                            ),
                            subtitle: Text(
                              supplier.phone ?? '-',
                              style: const TextStyle(
                                fontSize: AppFonts.fontSizeSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              sc.LucideIcons.chevronLeft,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            onTap: () => _onEntitySelected(supplier),
                          );
                        },
                      ),
                    ),
                ],
              ),

            if (_selectedEntity != null && widget.state is SuppliersLoaded)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        sc.LucideIcons.building2,
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
                              fontWeight: AppFonts.fontWeightSemiBold,
                              color: AppColors.text,
                            ),
                          ),
                          if (_selectedEntity.phone != null)
                            Text(
                              '${_selectedEntity.phone}',
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
                      onPressed: () => _clearSelection(),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        ),
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
