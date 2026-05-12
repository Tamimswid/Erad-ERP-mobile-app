import 'package:erad/features/customer_debts/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/invoice_cubit.dart';
import '../widgets/invoice_filters_widget.dart';
import '../widgets/invoice_stats_widget.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_empty_state_widget.dart';
import 'invoice_detail_page.dart';
import 'create_invoice_page.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  @override
  void initState() {
    super.initState();
    // Real-time stream automatically loads data when cubit is created
    // No need to manually call getAllInvoices
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      // appBar: AppBar(
      //   title: const Text(
      //     AppStrings.invoices,
      //     style: TextStyle(color: AppColors.text),
      //   ),
      //   backgroundColor: AppColors.surface,
      //   foregroundColor: AppColors.surface,
      //   surfaceTintColor: AppColors.surface,
      //   elevation: 0,
      // ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('إضافة فاتورة جديدة',style: TextStyle(color: AppColors.background),),
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoicePage(),
            ),
          );
        },
      ),
      body: BlocConsumer<InvoiceCubit, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is InvoiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InvoiceCubit>().getAllInvoices();
                    },
                    child: const Text('حاول ثانية'),
                  ),
                ],
              ),
            );
          }

          if (state is InvoiceFiltered) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  InvoiceFiltersWidget(
                    selectedType: context.read<InvoiceCubit>().selectedType,
                    selectedStatus: context.read<InvoiceCubit>().selectedStatus,
                    searchQuery: context.read<InvoiceCubit>().searchQuery,
                    dateFrom: context.read<InvoiceCubit>().dateFrom,
                    dateTo: context.read<InvoiceCubit>().dateTo,
                    onTypeChanged: (type) {
                      context.read<InvoiceCubit>().setTypeFilter(type);
                    },
                    onStatusChanged: (status) {
                      context.read<InvoiceCubit>().setStatusFilter(status);
                    },
                    onSearchChanged: (query) {
                      context.read<InvoiceCubit>().setSearchQuery(query);
                    },
                    onDateRangeChanged: (from, to) {
                      context.read<InvoiceCubit>().setDateRange(from, to);
                    },
                  ),
                  // Stats
                  InvoiceStatsWidget(
                    totalCount: state.totalCount,
                    paidCount: state.paidCount,
                    pendingCount: state.pendingCount,
                    totalAmount: state.totalAmount,
                  ),
                  
                  const SizedBox(height: 24),
                  // Invoice Cards Grid
                  _buildInvoiceGrid(state),
                ],
              ),
            );
          }

          // Show loading for any other state (including InvoiceInitial)
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceGrid(InvoiceFiltered state) {
    final allInvoices = <dynamic>[];
    allInvoices.addAll(state.salesInvoices);
    allInvoices.addAll(state.purchaseInvoices);

    if (allInvoices.isEmpty) {
      return const InvoiceEmptyStateWidget();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: allInvoices.length,
      itemBuilder: (context, index) {
        final invoice = allInvoices[index];
        final type = invoice.runtimeType.toString().contains('Sales') ? 'sale' : 'purchase';
        
        return InvoiceCardWidget(
          invoice: invoice,
          type: type,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceDetailPage(
                  invoiceId: invoice.id,
                  type: type,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
