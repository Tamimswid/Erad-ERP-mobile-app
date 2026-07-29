import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../suppliers/presentation/bloc/supplier_cubit.dart';
import '../widgets/party_list_tile.dart';
import 'customer_invoice_detail_page.dart';

class CustomerInvoicesPage extends StatelessWidget {
  final bool isSupplier;

  const CustomerInvoicesPage({super.key, this.isSupplier = false});

  @override
  Widget build(BuildContext context) {
    if (isSupplier) {
      return BlocProvider<SupplierCubit>(
        create: (_) => sl<SupplierCubit>()..getSuppliers(),
        child: const _PartyListContent(isSupplier: true),
      );
    }
    return BlocProvider<CustomerCubit>(
      create: (_) => sl<CustomerCubit>()..getCustomers(),
      child: const _PartyListContent(isSupplier: false),
    );
  }
}

class _PartyListContent extends StatefulWidget {
  final bool isSupplier;

  const _PartyListContent({required this.isSupplier});

  @override
  State<_PartyListContent> createState() => _PartyListContentState();
}

class _PartyListContentState extends State<_PartyListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSupplier ? 'فواتير مورد' : 'فواتير مشتري'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
          Expanded(child: widget.isSupplier ? _buildSuppliersList() : _buildCustomersList()),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerInitial || state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.profile_delete, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(state.message,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        if (state is CustomerLoaded) {
          final list = _searchQuery.isEmpty
              ? state.customers
              : state.customers.where((c) {
                  final q = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      (c.phone?.toLowerCase().contains(q) ?? false);
                }).toList();

          if (list.isEmpty) {
            return _emptyState(_searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final customer = list[index];
              return PartyListTile(
                name: customer.name,
                phone: customer.phone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerInvoiceDetailPage(
                      partyId: customer.id, partyName: customer.name, isSupplier: false,
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSuppliersList() {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        if (state is SupplierInitial || state is SupplierLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SupplierError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.profile_delete, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(state.message,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        if (state is SuppliersLoaded) {
          final list = _searchQuery.isEmpty
              ? state.suppliers
              : state.suppliers.where((s) {
                  final q = _searchQuery.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      (s.phone?.toLowerCase().contains(q) ?? false);
                }).toList();

          if (list.isEmpty) {
            return _emptyState(_searchQuery.isEmpty ? 'لا يوجد موردون' : 'لا توجد نتائج');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final supplier = list[index];
              return PartyListTile(
                name: supplier.name,
                phone: supplier.phone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerInvoiceDetailPage(
                      partyId: supplier.id, partyName: supplier.name, isSupplier: true,
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.profile_delete, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
