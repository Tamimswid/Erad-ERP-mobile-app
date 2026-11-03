import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart';
import '../../../../core/widgets/app_pagination_list.dart';
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
        create: (_) => sl<SupplierCubit>()..loadFirstPage(),
        child: const _PartyListContent(isSupplier: true),
      );
    }
    return BlocProvider<CustomerCubit>(
      create: (_) => sl<CustomerCubit>()..loadFirstPage(),
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (widget.isSupplier) {
        context.read<SupplierCubit>().searchSuppliers(value);
      } else {
        context.read<CustomerCubit>().searchCustomers(value);
      }
    });
  }

  bool get _hasQuery => _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      headers: [
        sc.AppBar(
          title: Text(widget.isSupplier ? 'فواتير مورد' : 'فواتير مشتري'),
          leading: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(sc.LucideIcons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: widget.isSupplier
                ? _buildSuppliersList()
                : _buildCustomersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        final cubit = context.read<CustomerCubit>();

        if (state is CustomerInitial || state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sc.LucideIcons.userX,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is CustomerLoaded) {
          if (state.customers.isEmpty) {
            return _emptyScrollView(
              () => cubit.loadFirstPage(showLoading: false),
              _hasQuery ? 'لا توجد نتائج' : 'لا يوجد عملاء',
            );
          }

          return RefreshIndicator(
            onRefresh: () => cubit.loadFirstPage(showLoading: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppPaginationSliverList(
                  itemCount: state.customers.length,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: cubit.loadMore,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  separator: const SizedBox(height: 8),
                  bottomSpace: 24,
                  itemBuilder: (context, index) {
                    final customer = state.customers[index];
                    return PartyListTile(
                      name: customer.name,
                      phone: customer.phone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerInvoiceDetailPage(
                            partyId: customer.id,
                            partyName: customer.name,
                            isSupplier: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSuppliersList() {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        final cubit = context.read<SupplierCubit>();

        if (state is SupplierInitial || state is SupplierLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SupplierError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sc.LucideIcons.userX,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is SuppliersLoaded) {
          if (state.suppliers.isEmpty) {
            return _emptyScrollView(
              () => cubit.loadFirstPage(showLoading: false),
              _hasQuery ? 'لا توجد نتائج' : 'لا يوجد موردون',
            );
          }

          return RefreshIndicator(
            onRefresh: () => cubit.loadFirstPage(showLoading: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppPaginationSliverList(
                  itemCount: state.suppliers.length,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: cubit.loadMore,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  separator: const SizedBox(height: 8),
                  bottomSpace: 24,
                  itemBuilder: (context, index) {
                    final supplier = state.suppliers[index];
                    return PartyListTile(
                      name: supplier.name,
                      phone: supplier.phone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerInvoiceDetailPage(
                            partyId: supplier.id,
                            partyName: supplier.name,
                            isSupplier: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _emptyScrollView(Future<void> Function() onRefresh, String message) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(message),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(sc.LucideIcons.userX, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
