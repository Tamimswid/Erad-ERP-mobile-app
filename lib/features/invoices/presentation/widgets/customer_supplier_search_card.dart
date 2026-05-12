import 'package:erad/features/suppliers/data/models/supplier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';

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
    _searchFocusNode.requestFocus();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant CustomerSupplierSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoiceType != widget.invoiceType) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    // Load customers for sale invoices
    if (widget.invoiceType == 'sale') {
      context.read<CustomerCubit>().getCustomers();
    } else {
      // Load suppliers for purchase invoices
      context.read<SupplierCubit>().getSuppliers();
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedEntity = null;
      });
      return;
    }

    final List<dynamic> allEntities = widget.invoiceType == 'sale' ? _allCustomers : _allSuppliers;
    
    if (allEntities.isEmpty) return;
    
    final results = allEntities.where((entity) {
      return entity.name.toLowerCase().contains(query.toLowerCase()) ||
             entity.phone.contains(query);
    }).toList();
    
    setState(() {
      _searchResults = results.take(10).toList();
      _selectedEntity = null;
    });
  }

  void _onSearchSubmitted(String query) {
    if (_searchResults.isNotEmpty) {
      _onEntitySelected(_searchResults.first);
    }
  }

  void _onEntitySelected(dynamic entity) {
    setState(() {
      _selectedEntity = entity;
      _searchResults = [];
    });
    
    _searchController.text = entity.name;
    
    // Unfocus to avoid keyboard issues
    _searchFocusNode.unfocus();
    
    if (widget.invoiceType == 'sale') {
      widget.onCustomerSelected(entity.id);
    } else {
      widget.onSupplierSelected(entity.id);
    }
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _selectedEntity = null;
      _searchResults = [];
    });
    
    // Clear focus and request it again to avoid keyboard issues
    _searchFocusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
    
    if (widget.invoiceType == 'sale') {
      widget.onCustomerSelected('');
    } else {
      widget.onSupplierSelected('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, customerState) {
        return BlocBuilder<SupplierCubit, SupplierState>(
          builder: (context, supplierState) {
            // Handle customer state for sale invoices
            if (widget.invoiceType == 'sale') {
              if (customerState is CustomerLoading) {
                _isLoading = true;
                _errorMessage = null;
              } else if (customerState is CustomerLoaded) {
                _isLoading = false;
                _allCustomers = customerState.customers;
                _errorMessage = null;
              } else if (customerState is CustomerError) {
                _isLoading = false;
                _errorMessage = customerState.message;
              }
            } else {
              // Handle supplier state for purchase invoices
              if (supplierState is SupplierLoading) {
                _isLoading = true;
                _errorMessage = null;
              } else if (supplierState is SuppliersLoaded) {
                _isLoading = false;
                _allSuppliers = supplierState.suppliers;
                _errorMessage = null;
              } else if (supplierState is SupplierError) {
                _isLoading = false;
                _errorMessage = supplierState.message;
              }
            }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.invoiceType == 'sale' ? Icons.person : Icons.business,
                    color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.invoiceType == 'sale' ? 'اختيار العميل' : 'اختيار المورد',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Search Field
              if (!_isLoading)
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    labelText: widget.invoiceType == 'sale' ? 'بحث العميل' : 'بحث المورد',
                    hintText: widget.invoiceType == 'sale' 
                        ? 'اكتب اسم العميل أو الكود أو الهاتف...' 
                        : 'اكتب اسم المورد أو الهاتف...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _clearSelection();
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                ),
              
              const SizedBox(height: 16),
              
              // Search Results Dropdown
              if (_searchResults.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.invoiceType == 'sale' ? Colors.blue.shade300 : Colors.green.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: (widget.invoiceType == 'sale' ? Colors.blue.shade50 : Colors.green.shade50),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              size: 16,
                              color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'اضغط ENTER للأول أو اختر من القائمة',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Results List
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final entity = _searchResults[index];
                            final isFirst = index == 0;
                            final isCustomer = entity is CustomerModel;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isFirst 
                                    ? (widget.invoiceType == 'sale' ? Colors.blue.shade50 : Colors.green.shade50)
                                    : Colors.transparent,
                                border: isFirst 
                                    ? Border(top: BorderSide(
                                        color: widget.invoiceType == 'sale' ? Colors.blue.shade300 : Colors.green.shade300
                                      ))
                                    : null,
                              ),
                              child: ListTile(
                                dense: false,
                                leading: CircleAvatar(
                                  backgroundColor: widget.invoiceType == 'sale' ? Colors.blue.shade100 : Colors.green.shade100,
                                  child: Icon(
                                    isCustomer ? Icons.person : Icons.business,
                                    color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  entity.name,
                                  style: TextStyle(
                                    fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                                    color: isFirst 
                                        ? (widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700)
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isCustomer && entity.code != null)
                                      Text(
                                        'الكود: ${entity.code}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    Text(
                                      '📱 ${entity.phone}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (isCustomer && entity.address != null)
                                      Text(
                                        '� ${entity.address}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: isFirst 
                                    ? Icon(
                                        Icons.keyboard_return,
                                        color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                                        size: 16,
                                      )
                                    : null,
                                onTap: () => _onEntitySelected(entity),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Selected Entity Display
              if (_selectedEntity != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.invoiceType == 'sale' 
                          ? [Colors.blue.shade50, Colors.blue.shade100]
                          : [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.invoiceType == 'sale' ? Colors.blue.shade300 : Colors.green.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.invoiceType == 'sale' ? Colors.blue.shade100 : Colors.green.shade100,
                        child: Icon(
                          widget.invoiceType == 'sale' ? Icons.person : Icons.business,
                          color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
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
                                color: widget.invoiceType == 'sale' ? Colors.blue.shade700 : Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '📱 ${_selectedEntity.phone}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          _clearSelection();
                          _searchFocusNode.requestFocus();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}
