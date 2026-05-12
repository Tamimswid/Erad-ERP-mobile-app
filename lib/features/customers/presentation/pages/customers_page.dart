import 'dart:async';
import 'dart:developer';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/customer_cubit.dart';
import '../widgets/customer_list_widget.dart';
import '../widgets/customer_form_widget.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  late CustomerCubit _customerCubit;

  @override
  void initState() {
    super.initState();
    _customerCubit = sl<CustomerCubit>();
    // Stream will auto-load data
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        context.read<CustomerCubit>().searchCustomers(query.trim());
      }
      // If empty, real-time stream will show all customers
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _customerCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<CustomerCubit, CustomerState>(
          listener: (context, state) {
            final cubit = context.read<CustomerCubit>();
            if (state is CustomerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is CustomerSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is CustomerLoaded) {
              log('UI[${cubit.hashCode}]: CustomerLoaded - ${state.customers.length} customers');
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with title and search
                _buildHeader(context),
                // Customers grid
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: _buildContent(state),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('إضافة عميل جديد', style: TextStyle(color: AppColors.background)),
          backgroundColor: AppColors.primary,
          onPressed: () {
            final cubit = context.read<CustomerCubit>();
            log('PAGE: FAB using CustomerCubit[${cubit.hashCode}]');
            _showAddCustomerDialog(context: context, onCustomerAdded: (customer) {
              log('PAGE: Dialog callback using CustomerCubit[${cubit.hashCode}]');
              cubit.createCustomer(customer);
            });
          },
        ),
      ),
    );
  }

  
  void _showAddCustomerDialog( {required BuildContext context ,required Function(CustomerModel customer) onCustomerAdded , CustomerModel? customerModel}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إضافة عميل جديد',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                 Expanded(
                  child: CustomerFormWidget(
                    customerModel: customerModel,
                    onTap: (customerModel) => onCustomerAdded(customerModel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _onSearchChanged(context, value),
          decoration: InputDecoration(
            hintText: 'بحث عن عميل...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CustomerState state) {
    return const CustomerListWidget();
  }
}
