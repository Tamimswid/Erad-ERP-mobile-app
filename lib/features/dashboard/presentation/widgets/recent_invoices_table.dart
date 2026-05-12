import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../invoices/presentation/bloc/invoice_cubit.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../../core/constants/app_constants.dart';

class RecentInvoicesTable extends StatefulWidget {
  final DateTimeRange? dateRange;
  const RecentInvoicesTable({super.key, this.dateRange});

  @override
  State<RecentInvoicesTable> createState() => _RecentInvoicesTableState();
}

class _RecentInvoicesTableState extends State<RecentInvoicesTable> {
  List<SalesInvoice>? _lastSalesInvoices;

  @override
  void initState() {
    super.initState();
    // Don't call getSalesInvoices here - dashboard already loads all invoices
  }

  String _getFilterName() {
    if (widget.dateRange == null) return 'هذا العام';
    final start = widget.dateRange!.start;
    final end = widget.dateRange!.end;
    // Check if it's a full year
    if (start.month == 1 && start.day == 1 && 
        end.month == 12 && end.day == 31 && 
        start.year == end.year) {
      return start.year.toString();
    }
    return 'مخصص';
  }

  List<SalesInvoice> _filterInvoices(List<SalesInvoice> invoices) {
    if (widget.dateRange == null) {
      // Default: current year
      final now = DateTime.now();
      return invoices.where((invoice) => invoice.invoiceDate.year == now.year).toList();
    }
    return invoices.where((invoice) {
      final invoiceDate = invoice.invoiceDate;
      return (invoiceDate.isAfter(widget.dateRange!.start) || 
              invoiceDate.isAtSameMomentAs(widget.dateRange!.start)) &&
             (invoiceDate.isBefore(widget.dateRange!.end) || 
              invoiceDate.isAtSameMomentAs(widget.dateRange!.end));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (state is InvoiceError) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'فشل تحميل الفواتير',
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (state is InvoiceFiltered) {
                final filtered = _filterInvoices(state.salesInvoices);
                final recentInvoices = filtered.take(5).toList();

                if (recentInvoices.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'لا توجد فواتير',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildInvoiceTable(recentInvoices);
              }

              if (state is FilteredSalesInvoicesLoaded) {
                // Store the sales data
                _lastSalesInvoices = state.invoices;

                // Apply additional filtering based on the widget's dateRange
                final filtered = _filterInvoices(state.invoices);
                final recentInvoices = filtered.take(5).toList();

                if (recentInvoices.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'لا تغريد فواتير رائعة',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildInvoiceTable(recentInvoices);
              }

              // Handle purchase invoice states - maintain the last sales data
              if (state is FilteredPurchaseInvoicesLoaded ||
                  state is PurchaseInvoicesLoaded) {
                if (_lastSalesInvoices != null) {
                  // Use the last stored sales data
                  final filtered = _filterInvoices(_lastSalesInvoices!);
                  final recentInvoices = filtered.take(5).toList();
                  return _buildInvoiceTable(recentInvoices);
                }
                // If no sales data yet, show empty state
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'لا تغريد فواتير رائعة',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTable(List<SalesInvoice> recentInvoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أحدث الفواتير (${_getFilterName()})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            // Header
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              children: [
                _buildHeaderCell('رقم الفاتورة'),
                _buildHeaderCell('العميل'),
                _buildHeaderCell('الإجمالي'),
                _buildHeaderCell('الحالة'),
              ],
            ),
            // Rows
            ...recentInvoices.map((invoice) {
              return TableRow(
                
                children: [
                  _buildDataCell('#${invoice.invoiceNumber}', isBold: true),
                  _buildDataCell(invoice.customerName ?? 'Null'),
                  _buildDataCell('${invoice.totalAmount} ${NumberFormatter.getCurrencySymbol()}'),
                  _buildStatusCell(invoice.paymentStatus.name),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color color;
    String text;

    switch (status) {
      case 'paid':
        color = Colors.green;
        text = 'مدفوعة';
        break;
      case 'pending':
      case 'draft':
      case 'sent':
        color = Colors.orange;
        text = 'معلقة';
        break;
      case 'overdue':
        color = Colors.red;
        text = 'متأخرة';
        break;
      case 'cancelled':
        color = Colors.grey;
        text = 'ملغاة';
        break;
      default:
        color = Colors.orange;
        text = 'معلقة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
