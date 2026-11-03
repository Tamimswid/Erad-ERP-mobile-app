import 'dart:async';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/customer_cubit.dart';
import '../widgets/customer_list_widget.dart';
import '../widgets/customer_form_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class CustomersPage extends StatefulWidget {
  final bool isLocal;

  const CustomersPage({super.key, this.isLocal = false});

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
    _customerCubit = sl<CustomerCubit>()..loadFirstPage();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _customerCubit.searchCustomers(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _customerCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,

        body: SafeArea(
          child: BlocConsumer<CustomerCubit, CustomerState>(
            listener: (context, state) {
              if (state is CustomerError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is CustomerSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
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
        ),
        floatingActionButton: widget.isLocal
            ? null
            : FloatingActionButton.extended(
                label: Text(
                  'إضافة عميل جديد',
                  style: TextStyle(color: AppColors.onPrimary),
                ),
                backgroundColor: AppColors.primary,
                onPressed: () {
                  _showAddCustomerDialog(context: context);
                },
              ),
      ),
    );
  }

  void _showAddCustomerDialog({
    required BuildContext context,
    CustomerModel? customerModel,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(dialogContext).size.height * 0.55,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إضافة عميل جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(sc.LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerFormWidget(
                    cubit: _customerCubit,
                    customerModel: customerModel,
                    onTap: (customerModel) {},
                  ),
                ],
              ),
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
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            IconButton(
              color: AppColors.text,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 25),
            ),

            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'بحث عن عميل...',
                  prefixIcon: const Icon(sc.LucideIcons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CustomerState state) {
    return const CustomerListWidget();
  }
}
