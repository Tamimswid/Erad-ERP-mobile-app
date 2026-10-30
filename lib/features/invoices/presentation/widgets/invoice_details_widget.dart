import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/number_formatter.dart';
import '../bloc/invoice_cubit.dart';
import '../../../../core/services/invoice_pdf_service.dart';

class InvoiceDetailsWidget extends StatelessWidget {
  final dynamic invoice; // Can be SalesInvoice or PurchaseInvoice

  const InvoiceDetailsWidget({Key? key, required this.invoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            onPressed: () => _editInvoice(context),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () => _deleteInvoice(context),
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () => _printInvoice(context),
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getPaymentStatusText(),
                            style: TextStyle(
                              color: _getPaymentStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          invoice is SalesInvoice
                              ? Icons.receipt_long
                              : Icons.shopping_cart,
                          color: invoice is SalesInvoice
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          invoice is SalesInvoice ? 'فاتورة بيع' : 'فاتورة شراء',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer/Supplier Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات الطرف الآخر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (invoice is SalesInvoice) ...[
                      _buildInfoRow('العميل:', invoice.customerName ?? 'غير محدد'),
                    ] else ...[
                      _buildInfoRow('المورد:', (invoice as PurchaseInvoice).supplierName ?? 'غير محدد'),
                    ],
                    _buildInfoRow(
                      'تاريخ الإصدار:',
                      DateFormat('yyyy-MM-dd').format(invoice is SalesInvoice ? invoice.invoiceDate : (invoice as PurchaseInvoice).invoiceDate),
                    ),
                    if (invoice is SalesInvoice && invoice.dueDate != null)
                      _buildInfoRow(
                        'تاريخ الاستحقاق:',
                        DateFormat('yyyy-MM-dd').format(invoice.dueDate!),
                      ),
                    if (invoice is PurchaseInvoice && invoice.dueDate != null)
                      _buildInfoRow(
                        'تاريخ الاستحقاق:',
                        DateFormat('yyyy-MM-dd').format(invoice.dueDate!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بنود الفاتورة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'المنتج',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'الكمية',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'السعر',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'الخصم',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'الإجمالي',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Items
                        ...invoice.items.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item.productName),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                AppUtils.formatNumber(item.quantity),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${AppUtils.formatNumber(item.unitPrice)} ${NumberFormatter.getCurrencySymbol()}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${AppUtils.formatNumber(item.discountAmount)} ${NumberFormatter.getCurrencySymbol()}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${AppUtils.formatNumber(item.totalPrice)} ${NumberFormatter.getCurrencySymbol()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Totals Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإجماليات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTotalRow('المجموع الفرعي:', invoice.subtotal),
                    _buildTotalRow('الضريبة (${invoice.taxRate}%):', invoice.taxAmount),
                    _buildTotalRow('الخصم:', invoice.discountAmount),
                    const Divider(),
                    _buildTotalRow(
                      'الإجمالي:',
                      invoice.totalAmount,
                      isBold: true,
                      isLarge: true,
                    ),
                    if (invoice.paidAmount != null) ...[
                      const SizedBox(height: 8),
                      _buildTotalRow('المدفوع:', invoice.paidAmount!),
                    ],
                    if (invoice.remainingAmount != null) ...[
                      _buildTotalRow('المتبقي:', invoice.remainingAmount!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes and Terms Card
            if (invoice.notes != null || invoice.terms != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات إضافية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (invoice.notes != null) ...[
                        const Text(
                          'ملاحظات:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(invoice.notes!),
                        const SizedBox(height: 12),
                      ],
                      if (invoice.terms != null) ...[
                        const Text(
                          'الشروط والأحكام:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(invoice.terms!),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Invoice Status Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الفاتورة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (invoice.status.name == 'draft') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateInvoiceStatus(context, 'sent'),
                            icon: const Icon(Icons.send),
                            label: const Text('إرسال'),
                          ),
                        ],
                        if (invoice.status.name == 'sent') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateInvoiceStatus(context, 'paid'),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('تحديد كمدفوعة'),
                          ),
                        ],
                        if (invoice.status.name == 'paid') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateInvoiceStatus(context, 'overdue'),
                            icon: const Icon(Icons.warning),
                            label: const Text('تأخير'),
                          ),
                        ],
                        if (invoice.status.name != 'cancelled') ...[
                          OutlinedButton.icon(
                            onPressed: () => _updateInvoiceStatus(context, 'cancelled'),
                            icon: const Icon(Icons.cancel),
                            label: const Text('إلغاء'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Payment Status Actions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الدفع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (invoice.paymentStatus.name == 'debt') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updatePaymentStatus(context, 'cash'),
                            icon: const Icon(Icons.attach_money),
                            label: const Text('تحديد كمدفوع نقدا'),
                          ),
                        ],
                        if (invoice.paymentStatus.name == 'cash') ...[
                          OutlinedButton.icon(
                            onPressed: () => _updatePaymentStatus(context, 'debt'),
                            icon: const Icon(Icons.money_off),
                            label: const Text('تحديد كمديون'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 16 : 14,
            ),
          ),
          Text(
            '${AppUtils.formatNumber(amount)} ${NumberFormatter.getCurrencySymbol()}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 18 : 14,
              color: isBold ? Theme.of(Get.context!).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    final status = invoice is SalesInvoice ? invoice.status.name : (invoice as PurchaseInvoice).status.name;
    return InvoiceStatus.fromString(status).getColor;
  }

  String _getStatusText() {
    final status = invoice is SalesInvoice ? invoice.status.name : (invoice as PurchaseInvoice).status.name;
    return InvoiceStatus.fromString(status).getArabicName;
  }

  Color _getPaymentStatusColor() {
    final status = invoice is SalesInvoice ? invoice.paymentStatus.name : (invoice as PurchaseInvoice).paymentStatus.name;
    return PaymentStatus.fromString(status).getColor;
  }

  String _getPaymentStatusText() {
    final status = invoice is SalesInvoice ? invoice.paymentStatus.name : (invoice as PurchaseInvoice).paymentStatus.name;
    return PaymentStatus.fromString(status).getArabicName;
  }

  void _editInvoice(BuildContext context) {
    // TODO: Navigate to edit invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: تعديل الفاتورة')),
    );
  }

  void _deleteInvoice(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('هل أنت متأكد من حذف فاتورة ${invoice.invoiceNumber}؟'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingContext) => const PopScope(
                          canPop: false,
                          child: AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 16),
                                Text('جاري حذف الفاتورة...'),
                              ],
                            ),
                          ),
                        ),
                      );

                      try {
                        if (invoice is SalesInvoice) {
                          await context.read<InvoiceCubit>().deleteSalesInvoiceWithBalanceAdjustment(invoice as SalesInvoice);
                        } else if (invoice is PurchaseInvoice) {
                          await context.read<InvoiceCubit>().deletePurchaseInvoice(invoice.id);
                        }
                      } finally {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(true);
                        }
                      }
                    },
                    child: const Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printInvoice(BuildContext context) {
    InvoicePdfService.generateAndPrintInvoice(invoice);
  }

  void _updateInvoiceStatus(BuildContext context, String newStatus) {
    if (invoice is SalesInvoice) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.values.firstWhere((e) => e.name == newStatus, orElse: () => InvoiceStatus.draft),
        updatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updateSalesInvoice(updatedInvoice);
    } else if (invoice is PurchaseInvoice) {
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.values.firstWhere((e) => e.name == newStatus, orElse: () => InvoiceStatus.draft),
        updatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updatePurchaseInvoice(updatedInvoice);
    }
  }

  void _updatePaymentStatus(BuildContext context, String newStatus) async {
    if (invoice is SalesInvoice) {
      // Use the new method that also updates customer balance
      await context.read<InvoiceCubit>().updateInvoicePaymentStatusWithBalance(
        invoice as SalesInvoice,
        newStatus,
      );

      // Show success message
      if (newStatus == 'cash') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد الفاتورة كمدفوعة وتم تحديث رصيد العميل')),
        );
      }
    } else if (invoice is PurchaseInvoice) {
      final updatedInvoice = (invoice as PurchaseInvoice).copyWith(
        paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == newStatus, orElse: () => PaymentStatus.cash),
        updatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updatePurchaseInvoice(updatedInvoice);
    }
  }
}

// Extension to get context for theme access
extension Get on Widget {
  static BuildContext? context;
}
