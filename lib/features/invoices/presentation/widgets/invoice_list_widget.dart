import 'package:flutter/material.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/invoice_cubit.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class InvoiceListWidget extends StatelessWidget {
  final String type;

  const InvoiceListWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sales invoices
        if (type == 'sale' && state is SalesInvoicesLoaded) {
          final invoices = state.invoices;
          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sc.LucideIcons.receiptText,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text('لا يوجد فواتير بيع'),
                  SizedBox(height: 8),
                  Text('أضف فاتورة جديدة للبدء'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return SalesInvoiceCard(invoice: invoice);
            },
          );
        }

        // Purchase invoices
        if (type == 'purchase' && state is PurchaseInvoicesLoaded) {
          final invoices = state.invoices;
          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sc.LucideIcons.receiptText,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text('لا يوجد فواتير شراء'),
                  SizedBox(height: 8),
                  Text('أضف فاتورة جديدة للبدء'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return PurchaseInvoiceCard(invoice: invoice);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class SalesInvoiceCard extends StatelessWidget {
  final SalesInvoice invoice;

  const SalesInvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.muted,
          child: Icon(sc.LucideIcons.tag, color: AppColors.primary),
        ),
        title: Text('فاتورة #${invoice.invoiceNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العميل: ${invoice.customerName ?? 'غير محدد'}'),
            Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${invoice.totalAmount.toStringAsFixed(2)} ل.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.moneyIn,
              ),
            ),
            Text(
              invoice.paymentStatus.name,
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(invoice.paymentStatus.name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return PaymentStatus.fromString(status).getColor;
  }
}

class PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;

  const PurchaseInvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.muted,
          child: Icon(sc.LucideIcons.shoppingCart, color: AppColors.primary),
        ),
        title: Text('فاتورة #${invoice.invoiceNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المورد: ${invoice.supplierName ?? 'غير محدد'}'),
            Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${invoice.totalAmount.toStringAsFixed(2)} ل.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.moneyIn,
              ),
            ),
            Text(
              invoice.paymentStatus.name,
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(invoice.paymentStatus.name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return PaymentStatus.fromString(status).getColor;
  }
}
