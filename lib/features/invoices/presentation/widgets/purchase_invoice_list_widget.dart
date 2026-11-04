import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/presentation/pages/edit_invoice_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/invoice_cubit.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class PurchaseInvoiceListWidget extends StatefulWidget {
  const PurchaseInvoiceListWidget({Key? key}) : super(key: key);

  @override
  State<PurchaseInvoiceListWidget> createState() =>
      _PurchaseInvoiceListWidgetState();
}

class _PurchaseInvoiceListWidgetState extends State<PurchaseInvoiceListWidget> {
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<InvoiceCubit>().getPurchaseInvoices();
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
                icon: const Icon(sc.LucideIcons.plus),
                label: const Text('فاتورة شراء جديدة'),
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
                      Icon(
                        sc.LucideIcons.circleAlert,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<InvoiceCubit>().getPurchaseInvoices(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              } else if (state is PurchaseInvoicesLoaded) {
                if (state.invoices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sc.LucideIcons.shoppingCart,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text('لا توجد فواتير شراء'),
                        const SizedBox(height: 8),
                        Text('أنشئ فاتورة شراء جديدة للبدء'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<InvoiceCubit>().getPurchaseInvoices(),
                  child: ListView.builder(
                    itemCount: state.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = state.invoices[index];
                      return PurchaseInvoiceCard(invoice: invoice);
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
    context.read<InvoiceCubit>().getPurchaseInvoices();
  }

  void _showCreateInvoiceDialog(BuildContext context) {
    // TODO: Navigate to purchase invoice creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: إنشاء فاتورة شراء جديدة')),
    );
  }
}

class PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;

  const PurchaseInvoiceCard({Key? key, required this.invoice})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            sc.LucideIcons.shoppingCart,
            color: AppColors.warning,
          ),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المورد: ${invoice.supplierName ?? "غير محدد"}'),
            const SizedBox(height: 4),
            Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
            if (invoice.dueDate != null)
              Text(
                'تاريخ الاستحقاق: ${invoice.dueDate!.toString().split(' ')[0]}',
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${invoice.totalAmount.toStringAsFixed(2)} ل.س',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
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
    return PaymentStatus.fromString(invoice.paymentStatus.name).getColor;
  }

  String _getStatusText() {
    return PaymentStatus.fromString(invoice.paymentStatus.name).getArabicName;
  }

  void _showInvoiceDetails(BuildContext context, PurchaseInvoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(invoice.invoiceNumber),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('النوع: شراء'),
              const SizedBox(height: 8),
              Text('الحالة: ${_getStatusText()}'),
              const SizedBox(height: 8),
              Text('المورد: ${invoice.supplierName ?? "غير محدد"}'),
              const SizedBox(height: 8),
              Text(
                'تاريخ الإصدار: ${invoice.invoiceDate.toString().split(' ')[0]}',
              ),
              if (invoice.dueDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'تاريخ الاستحقاق: ${invoice.dueDate!.toString().split(' ')[0]}',
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'المجموع الفرعي: ${invoice.subtotal.toStringAsFixed(2)} ل.س',
              ),
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
                Text(
                  'المتبقي: ${invoice.remainingAmount.toStringAsFixed(2)} ل.س',
                ),
              ],
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${invoice.notes}'),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditInvoicePage(
                            invoiceId: invoice.id,
                            isSales: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('تعديل'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, invoice);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PurchaseInvoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(sc.LucideIcons.triangleAlert, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<InvoiceCubit>().deletePurchaseInvoice(
                        invoice.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
