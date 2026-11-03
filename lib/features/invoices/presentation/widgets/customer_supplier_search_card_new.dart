import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/data/models/supplier.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class CustomerSupplierSearchCard extends StatefulWidget {
  final String invoiceType;
  final Function(String) onCustomerSelected;
  final Function(String) onSupplierSelected;

  const CustomerSupplierSearchCard({
    super.key,
    required this.invoiceType,
    required this.onCustomerSelected,
    required this.onSupplierSelected,
  });

  @override
  State<CustomerSupplierSearchCard> createState() => _CustomerSupplierSearchCardState();
}

class _CustomerSupplierSearchCardState extends State<CustomerSupplierSearchCard> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<CustomerModel> _allCustomers = [];
  List<SupplierModel> _allSuppliers = [];
  List<dynamic> _searchResults = [];
  dynamic _selectedEntity;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomerSupplierSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoiceType != widget.invoiceType) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
      _selectedEntity = null;
    });

    if (widget.invoiceType == 'sale') {
      _loadCustomers();
    } else {
      _loadSuppliers();
    }
  }

  void _loadCustomers() async {
    final cubit = context.read<CustomerCubit>();
    await cubit.getCustomers();
    
    if (mounted) {
      final state = cubit.state;
      if (state is CustomerLoaded) {
        setState(() {
          _isLoading = false;
          _allCustomers = state.customers;
        });
      } else if (state is CustomerError) {
        setState(() {
          _isLoading = false;
          _errorMessage = state.message;
        });
      }
    }
  }

  void _loadSuppliers() async {
    final cubit = context.read<SupplierCubit>();
    await cubit.getSuppliers();
    
    if (mounted) {
      final state = cubit.state;
      if (state is SuppliersLoaded) {
        setState(() {
          _isLoading = false;
          _allSuppliers = state.suppliers;
        });
      } else if (state is SupplierError) {
        setState(() {
          _isLoading = false;
          _errorMessage = state.message;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final List<dynamic> allEntities = widget.invoiceType == 'sale' ? _allCustomers : _allSuppliers;

    if (allEntities.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = allEntities.where((entity) {
      if (entity is CustomerModel) {
        return entity.name.toLowerCase().contains(query.toLowerCase()) ||
               entity.code.toLowerCase().contains(query.toLowerCase()) ||
               (entity.phone?.contains(query) ?? false);
      } else if (entity is SupplierModel) {
        return entity.name.toLowerCase().contains(query.toLowerCase()) ||
               (entity.phone?.contains(query) ?? false);
      }
      return false;
    }).toList();

    setState(() {
      _searchResults = results.take(10).toList();
    });
  }

  void _onEntitySelected(dynamic entity) {
    setState(() {
      _selectedEntity = entity;
      _searchResults = [];
      _searchFocusNode.unfocus();
    });

    _searchController.text = entity.name;

    if (widget.invoiceType == 'sale') {
      widget.onCustomerSelected(entity.id);
    } else {
      widget.onSupplierSelected(entity.id);
    }
  }

  void _clearSelection() {
    _searchController.clear();
    _selectedEntity = null;
    _searchResults = [];
    _searchFocusNode.requestFocus();

    if (widget.invoiceType == 'sale') {
      widget.onCustomerSelected('');
    } else {
      widget.onSupplierSelected('');
    }
  }

  Color get _primaryColor => widget.invoiceType == 'sale' ? AppColors.primary : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.invoiceType == 'sale' ? sc.LucideIcons.user : sc.LucideIcons.building2,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.invoiceType == 'sale' ? 'اختيار العميل' : 'اختيار المورد',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(sc.LucideIcons.circleAlert, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(sc.LucideIcons.refreshCw, size: 20),
                    onPressed: _loadData,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),

          // Search Field
          if (!_isLoading && _errorMessage == null)
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: widget.invoiceType == 'sale' ? 'بحث عن عميل' : 'بحث عن مورد',
                hintText: widget.invoiceType == 'sale'
                    ? 'اكتب اسم العميل أو الكود أو الهاتف...'
                    : 'اكتب اسم المورد أو الهاتف...',
                prefixIcon: Icon(sc.LucideIcons.search, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
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

          // Search Results Dropdown
          if (_searchResults.isNotEmpty && !_isLoading)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final entity = _searchResults[index];
                  final isFirst = index == 0;
                  final isCustomer = entity is CustomerModel;

                  return Container(
                    decoration: BoxDecoration(
                      color: isFirst ? _primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                      border: index > 0
                          ? const Border(top: BorderSide(color: AppColors.divider))
                          : null,
                    ),
                    child: ListTile(
                      dense: false,
                      leading: CircleAvatar(
                        backgroundColor: _primaryColor.withValues(alpha: 0.15),
                        child: Icon(
                          isCustomer ? sc.LucideIcons.user : sc.LucideIcons.building2,
                          color: _primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        entity.name,
                        style: TextStyle(
                          fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                          color: isFirst ? _primaryColor : AppColors.text,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            '${entity.phone ?? 'لا يوجد'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (isCustomer && entity.address != null && entity.address!.isNotEmpty)
                            Text(
                              '${entity.address}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: isFirst
                          ? Icon(sc.LucideIcons.cornerDownLeft, color: _primaryColor, size: 18)
                          : null,
                      onTap: () => _onEntitySelected(entity),
                    ),
                  );
                },
              ),
            ),

          // Selected Entity Display
          if (_selectedEntity != null && !_isLoading)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    _primaryColor.withValues(alpha: 0.05),
                    _primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryColor.withValues(alpha: 0.15),
                    child: Icon(
                      widget.invoiceType == 'sale' ? sc.LucideIcons.user : sc.LucideIcons.building2,
                      color: _primaryColor,
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '📱 ${_selectedEntity.phone ?? 'لا يوجد'}',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(sc.LucideIcons.pencil, size: 20),
                    onPressed: () {
                      _clearSelection();
                    },
                    color: _primaryColor,
                    tooltip: 'تعديل',
                  ),
                ],
              ),
            ),

          // No results message
          if (_searchController.text.isNotEmpty && _searchResults.isEmpty && !_isLoading && _errorMessage == null)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(sc.LucideIcons.search, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
