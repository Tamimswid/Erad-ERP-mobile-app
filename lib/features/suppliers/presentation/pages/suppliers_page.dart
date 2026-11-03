import 'dart:async';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/invoices/presentation/widgets/invoice_details_widget.dart';
import 'package:erad/features/suppliers/data/models/supplier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/supplier_cubit.dart';
import '../widgets/supplier_form_widget.dart';
import '../widgets/supplier_list_widget.dart';
import '../../data/repositories/supplier_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class SuppliersPage extends StatefulWidget {
  final bool isLocal;

  const SuppliersPage({super.key, this.isLocal = false});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  late SupplierCubit _supplierCubit;

  @override
  void initState() {
    super.initState();
    _supplierCubit = SupplierCubit(supplierRepository: sl<SupplierRepository>())
      ..loadFirstPage();
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
      _supplierCubit.searchSuppliers(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _supplierCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<SupplierCubit, SupplierState>(
            listener: (context, state) {
              if (state is SupplierError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is SupplierSuccess) {
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
                  // Suppliers grid
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
                onPressed: () {
                  _showAddSupplierDialog(context, (supplier) {
                    context.read<SupplierCubit>().createSupplier(supplier);
                  });
                },
                label: Text(
                  'إضافة مورد',
                  style: TextStyle(color: AppColors.onPrimary),
                ),
                backgroundColor: AppColors.primary,
              ),
      ),
    );
  }

  void _showAddSupplierDialog(
    BuildContext context,
    Function(SupplierModel) onSubmit,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.5,
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
                        'إضافة مورد جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(sc.LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SupplierFormWidget(
                    cubit: _supplierCubit,
                    onSubmit: (supplier) {
                      Navigator.pop(context);
                    },
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
                  hintText: 'بحث عن مورد...',
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

  Widget _buildContent(SupplierState state) {
    return const SupplierListWidget();
  }
}
