import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/invoice_cubit.dart';
import '../widgets/discount_widget.dart';
import '../widgets/payment_status_dialog.dart';
import '../widgets/delete_invoice_dialog.dart';
import '../widgets/cancel_invoice_dialog.dart';
import '../../data/models/sales_invoice.dart';
import '../../data/models/purchase_invoice.dart';

class InvoiceManagementPage extends StatefulWidget {
  final dynamic invoice;
  final String type;

  const InvoiceManagementPage({
    super.key,
    required this.invoice,
    required this.type,
  });

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  late double _discountAmount;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice is SalesInvoice) {
      _discountAmount = (widget.invoice as SalesInvoice).discountAmount;
    } else if (widget.invoice is PurchaseInvoice) {
      _discountAmount = (widget.invoice as PurchaseInvoice).discountAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الفاتورة #${_getInvoiceNumber()}'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'حفظ' : 'تعديل',
          ),
        ],
      ),
      body: BlocListener<InvoiceCubit, InvoiceState>(
        listener: (context, state) {
          if (state is SalesInvoiceUpdated || state is PurchaseInvoiceUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الفاتورة بنجاح')),
            );
            setState(() {
              _isEditing = false;
            });
          } else if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceSummary(),
              const SizedBox(height: 24),
              if (_isEditing) _buildDiscountSection(),
              const SizedBox(height: 24),
              _buildActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الفاتورة',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('رقم الفاتورة', _getInvoiceNumber()),
            _buildSummaryRow('التاريخ', _getFormattedDate()),
            _buildSummaryRow(
              widget.type == 'sale' ? 'العميل' : 'المورد',
              _getCustomerOrSupplierName(),
            ),
            _buildSummaryRow('الحالة', _getStatusName()),
            _buildSummaryRow('المبلغ الإجمالي', '${_getTotalAmount().toStringAsFixed(2)} ل.س'),
            if (_discountAmount > 0)
              _buildSummaryRow(
                'الخصم',
                '${_discountAmount.toStringAsFixed(2)} ل.س',
                isDiscount: true,
              ),
            _buildSummaryRow(
              'المبلغ بعد الخصم',
              '${(_getTotalAmount() - _discountAmount).toStringAsFixed(2)} ل.س',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return DiscountWidget(
      subtotal: _getSubtotal(),
      discountAmount: _discountAmount,
      onDiscountChanged: (amount) {
        setState(() {
          _discountAmount = amount;
        });
      },
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإجراءات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'تحديث حالة الدفع',
                  Icons.payment,
                  Colors.blue,
                  _updatePaymentStatus,
                ),
                _buildActionButton(
                  'إلغاء الفاتورة',
                  Icons.cancel,
                  Colors.orange,
                  _cancelInvoice,
                ),
                _buildActionButton(
                  'حذف الفاتورة',
                  Icons.delete,
                  Colors.red,
                  _deleteInvoice,
                ),
                _buildActionButton(
                  'تصدير PDF',
                  Icons.picture_as_pdf,
                  Colors.green,
                  _exportToPdf,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _saveChanges() {
    if (widget.invoice is SalesInvoice) {
      final updatedInvoice = (widget.invoice as SalesInvoice).copyWith(
        discountAmount: _discountAmount,
        updatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updateSalesInvoice(updatedInvoice);
    } else if (widget.invoice is PurchaseInvoice) {
      final updatedInvoice = (widget.invoice as PurchaseInvoice).copyWith(
        discountAmount: _discountAmount,
        updatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updatePurchaseInvoice(updatedInvoice);
    }
  }

  void _updatePaymentStatus() {
    showDialog(
      context: context,
      builder: (context) => PaymentStatusDialog(
        currentStatus: _getPaymentStatus(),
        onStatusChanged: (newStatus) {
          // Cubit'i kullanarak status güncelle
          context.read<InvoiceCubit>().updateInvoiceStatus(widget.invoice, newStatus);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _cancelInvoice() {
    showDialog(
      context: context,
      builder: (context) => CancelInvoiceDialog(
        invoiceNumber: _getInvoiceNumber(),
        onConfirm: () {
          // Cubit'i kullanarak faturayı iptal et
          _updateInvoiceStatus('cancelled');
        },
      ),
    );
  }

  void _deleteInvoice() {
    showDialog(
      context: context,
      builder: (context) => DeleteInvoiceDialog(
        invoiceNumber: _getInvoiceNumber(),
        onConfirm: () {
          // Cubit'i kullanarak faturayı sil
          if (widget.type == 'sale') {
            context.read<InvoiceCubit>().deleteSalesInvoice(widget.invoice.id);
          } else {
            context.read<InvoiceCubit>().deletePurchaseInvoice(widget.invoice.id);
          }
        },
      ),
    );
  }

  void _exportToPdf() {
    // Navigate to PDF export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تصدير الفاتورة كـ PDF')),
    );
  }

  void _updateInvoiceStatus(String newStatus) {
    // Cubit'in yeni method'unu kullanarak status güncelle
    context.read<InvoiceCubit>().updateInvoiceStatus(widget.invoice, newStatus);
  }

  // Helper methods
  String _getInvoiceNumber() {
    if (widget.invoice is SalesInvoice) {
      return (widget.invoice as SalesInvoice).invoiceNumber;
    } else if (widget.invoice is PurchaseInvoice) {
      return (widget.invoice as PurchaseInvoice).invoiceNumber;
    }
    return '';
  }

  String _getFormattedDate() {
    DateTime date;
    if (widget.invoice is SalesInvoice) {
      date = (widget.invoice as SalesInvoice).invoiceDate;
    } else if (widget.invoice is PurchaseInvoice) {
      date = (widget.invoice as PurchaseInvoice).invoiceDate;
    } else {
      date = DateTime.now();
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getCustomerOrSupplierName() {
    if (widget.invoice is SalesInvoice) {
      return (widget.invoice as SalesInvoice).customerName ?? 'غير محدد';
    } else if (widget.invoice is PurchaseInvoice) {
      return (widget.invoice as PurchaseInvoice).supplierName ?? 'غير محدد';
    }
    return '';
  }

  String _getStatusName() {
    String status;
    if (widget.invoice is SalesInvoice) {
      status = (widget.invoice as SalesInvoice).paymentStatus.name;
    } else if (widget.invoice is PurchaseInvoice) {
      status = (widget.invoice as PurchaseInvoice).paymentStatus.name;
    } else {
      status = 'unknown';
    }

    switch (status) {
      case 'paid':
        return 'مدفوعة';
      case 'pending':
        return 'معلقة';
      case 'overdue':
        return 'متأخرة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return status;
    }
  }

  String _getPaymentStatus() {
    if (widget.invoice is SalesInvoice) {
      return (widget.invoice as SalesInvoice).paymentStatus.name;
    } else if (widget.invoice is PurchaseInvoice) {
      return (widget.invoice as PurchaseInvoice).paymentStatus.name;
    }
    return '';
  }

  double _getTotalAmount() {
    if (widget.invoice is SalesInvoice) {
      return (widget.invoice as SalesInvoice).totalAmount;
    } else if (widget.invoice is PurchaseInvoice) {
      return (widget.invoice as PurchaseInvoice).totalAmount;
    }
    return 0.0;
  }

  double _getSubtotal() {
    if (widget.invoice is SalesInvoice) {
      return (widget.invoice as SalesInvoice).subtotal;
    } else if (widget.invoice is PurchaseInvoice) {
      return (widget.invoice as PurchaseInvoice).subtotal;
    }
    return 0.0;
  }
}
