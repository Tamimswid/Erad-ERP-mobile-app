import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/presentation/pages/edit_invoice_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/invoice_cubit.dart';

class SalesInvoiceListWidget extends StatefulWidget {
  const SalesInvoiceListWidget({Key? key}) : super(key: key);

  @override
  State<SalesInvoiceListWidget> createState() => _SalesInvoiceListWidgetState();
}

class _SalesInvoiceListWidgetState extends State<SalesInvoiceListWidget> {
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<InvoiceCubit>().getSalesInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('الحالة:'),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                  DropdownMenuItem(value: 'sent', child: Text('مرسلة')),
                  DropdownMenuItem(value: 'paid', child: Text('مدفوعة')),
                  DropdownMenuItem(value: 'overdue', child: Text('متأخرة')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                    _filterInvoices(value);
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateInvoiceDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('فاتورة جديدة'),
              ),
            ],
          ),
        ),
        // Invoices list
        Expanded(
          child: BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InvoiceError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<InvoiceCubit>().getSalesInvoices(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              } else if (state is SalesInvoicesLoaded) {
                if (state.invoices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد فواتير مبيعات'),
                        SizedBox(height: 8),
                        Text('أنشئ فاتورة مبيعات جديدة للبدء'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<InvoiceCubit>().getSalesInvoices(),
                  child: ListView.builder(
                    itemCount: state.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = state.invoices[index];
                      return SalesInvoiceCard(invoice: invoice);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  void _filterInvoices(String status) {
    // TODO: Implement filtering by status
    context.read<InvoiceCubit>().getSalesInvoices();
  }

  void _showCreateInvoiceDialog(BuildContext context) {
    // TODO: Navigate to invoice creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: إنشاء فاتورة جديدة')),
    );
  }
}

class SalesInvoiceCard extends StatelessWidget {
  final SalesInvoice invoice;

  const SalesInvoiceCard({Key? key, required this.invoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
          ),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العميل: ${invoice.customerName ?? "غير محدد"}'),
            const SizedBox(height: 4),
            Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
            if (invoice.dueDate != null)
              Text('تاريخ الاستحقاق: ${invoice.dueDate.toString().split(' ')[0]}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${invoice.totalAmount.toStringAsFixed(2)} ل.س',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getPaymentStatusText(),
                style: TextStyle(
                  color: _getPaymentStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _showInvoiceDetails(context, invoice);
        },
      ),
    );
  }

  Color _getStatusColor() {
    return InvoiceStatus.fromString(invoice.status.name).getColor;
  }

  Color _getPaymentStatusColor() {
    return PaymentStatus.fromString(invoice.paymentStatus.name).getColor;
  }

  IconData _getStatusIcon() {
    switch (invoice.status.name) {
      case 'draft':
        return Icons.drafts;
      case 'sent':
        return Icons.send;
      case 'paid':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.pending;
    }
  }

  String _getStatusText() {
    return InvoiceStatus.fromString(invoice.status.name).getArabicName;
  }

  String _getPaymentStatusText() {
    return PaymentStatus.fromString(invoice.paymentStatus.name).getArabicName;
  }

  void _showInvoiceDetails(BuildContext context, SalesInvoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(invoice.invoiceNumber),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('النوع: بيع'),
              const SizedBox(height: 8),
              Text('حالة الفاتورة: ${_getStatusText()}'),
              const SizedBox(height: 4),
              Text('حالة الدفع: ${_getPaymentStatusText()}'),
              const SizedBox(height: 8),
              Text('العميل: ${invoice.customerName ?? "غير محدد"}'),
              const SizedBox(height: 8),
              Text('تاريخ الإصدار: ${invoice.invoiceDate.toString().split(' ')[0]}'),
              if (invoice.dueDate != null) ...[
                const SizedBox(height: 4),
                Text('تاريخ الاستحقاق: ${invoice.dueDate.toString().split(' ')[0]}'),
              ],
              const SizedBox(height: 8),
              Text('المجموع الفرعي: ${invoice.subtotal.toStringAsFixed(2)} ل.س'),
              Text('الضريبة: ${invoice.taxAmount.toStringAsFixed(2)} ل.س'),
              Text('الخصم: ${invoice.discountAmount.toStringAsFixed(2)} ل.س'),
              Text(
                'الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)} ل.س',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (invoice.paidAmount > 0) ...[
                const SizedBox(height: 4),
                Text('المدفوع: ${invoice.paidAmount.toStringAsFixed(2)} ل.س'),
              ],
              if (invoice.remainingAmount > 0) ...[
                const SizedBox(height: 4),
                Text('المتبقي: ${invoice.remainingAmount.toStringAsFixed(2)} ل.س'),
              ],
              if (invoice.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${invoice.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditInvoicePage(
                    invoiceId: invoice.id,
                    isSales: true,
                  ),
                ),
              );
            },
            child: const Text('تعديل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, invoice);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SalesInvoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف الفاتورة ${invoice.invoiceNumber}؟'),
            const SizedBox(height: 12),
            const Text(
              'سيتم حذف جميع البيانات المرتبطة بهذه الفاتورة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• عناصر الفاتورة'),
            const SizedBox(height: 8),
            const Text(
              'هذا الإجراء لا يمكن التراجع عنه',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InvoiceCubit>().deleteSalesInvoice(invoice.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
