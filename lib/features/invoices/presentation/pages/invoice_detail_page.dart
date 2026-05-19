import 'dart:developer';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../data/models/sales_invoice.dart';
import '../../data/models/purchase_invoice.dart';
import '../../data/models/invoice_status.dart';
import '../../data/models/payment_status.dart';
import '../bloc/invoice_cubit.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../../../core/services/pdf_invoice_service.dart';
import '../widgets/payment_status_dialog.dart';
import '../widgets/invoice_status_dialog.dart';
import '../widgets/delete_invoice_dialog.dart';
import '../widgets/invoice_detail_header_widget.dart';
import '../widgets/invoice_info_card_widget.dart';
import '../widgets/invoice_totals_widget.dart';
import '../widgets/invoice_action_buttons_widget.dart';
import 'package:erad/features/products/presentation/bloc/product_cubit.dart';
import '../../../../core/di/services_locator.dart' as sl;
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'edit_invoice_page.dart';

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  final String type;

  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<InvoiceCubit>(),
      child: InvoiceDetailView(invoiceId: invoiceId, type: type),
    );
  }
}

class InvoiceDetailView extends StatefulWidget {
  final String invoiceId;
  final String type;

  const InvoiceDetailView({
    super.key,
    required this.invoiceId,
    required this.type,
  });

  @override
  State<InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends State<InvoiceDetailView> {
  dynamic invoice;
  bool isLoading = true;
  bool isDeleting = false;
  bool isGeneratingPdf = false;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
  }

  bool _hasLoadedInvoice = false;

  Future<void> _loadInvoice(BuildContext context) async {
    try {
      final cubit = context.read<InvoiceCubit>();

      if (widget.type == 'sale') {
        await cubit.getSalesInvoiceById(widget.invoiceId);
      } else {
        await cubit.getPurchaseInvoiceById(widget.invoiceId);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) => InvoiceCubit(sl.sl<InvoiceRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              ProductCubit(productRepository: sl.sl<ProductRepository>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (!_hasLoadedInvoice) {
            _hasLoadedInvoice = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadInvoice(context);
            });
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: BlocListener<ProductCubit, ProductState>(
                listener: (context, state) {
                  if (state is ProductSingleLoaded) {
                    setState(() {
                      for (int i = 0; i < products.length; i++) {
                        if (products[i]['item'].productId == state.product.id) {
                          products[i]['product'] = state.product;
                        }
                      }
                    });
                  }
                },
                child: BlocListener<InvoiceCubit, InvoiceState>(
                  listener: (context, state) {
                    if (state is SalesInvoiceLoaded ||
                        state is PurchaseInvoiceLoaded) {
                      setState(() {
                        invoice = state is SalesInvoiceLoaded
                            ? state.invoice
                            : (state as PurchaseInvoiceLoaded).invoice;
                        isLoading = false;
                        products = (invoice.items as List)
                            .map<Map<String, dynamic>>(
                              (item) => {'item': item, 'product': null},
                            )
                            .toList();
                   
                      });
                      for (var item in invoice.items) {
                        if (item.productId != null &&
                            item.productId!.isNotEmpty) {
                          context.read<ProductCubit>().getProduct(
                            item.productId!,
                          );
                        }
                      }
                    } else if (state is InvoiceError) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
                      setState(() {
                        isLoading = false;
                      });
                    } else if (state is SalesInvoiceUpdated ||
                        state is PurchaseInvoiceUpdated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث الفاتورة بنجاح'),
                        ),
                      );
                      _loadInvoice(context); // Fix: Pass context parameter
                    } else if (state is SalesInvoiceDeleted ||
                        state is PurchaseInvoiceDeleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف الفاتورة')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: BlocBuilder<InvoiceCubit, InvoiceState>(
                    builder: (context, state) {
                      if (isLoading || state is InvoiceLoading || isDeleting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (invoice == null) {
                        return const Center(
                          child: Text('لم يتم العثور على الفاتورة'),
                        );
                      }

                      return _buildNewInvoiceDetail();
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewInvoiceDetail() {

    final cubit = context.read<InvoiceCubit>();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InvoiceDetailHeaderWidget(
                invoiceNumber: _getInvoiceNumber(),
                onBackPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              // Info Card with Products
              InvoiceInfoCardWidget(
                invoiceDate: _formatDate(_getInvoiceDate()),
                customerName: _getCustomerOrSupplierName(),
                products: _getProductsList(),
              ),


              // Totals
              InvoiceTotalsWidget(
                subtotal: _getSubtotal(),
                discount: _getDiscountAmount(),
                total: _getTotalAmount(),
              ),


              // Action Buttons
              InvoiceActionButtonsWidget(
                onExportPdf: _generatePdf,
                onEdit: _editInvoice,
                onUpdateInvoiceStatus: () => _updateInvoiceStatus(
                  onUpdate: (newState) => _updateInvoiceStatusOptimistic(newState, cubit),
                ),
                onUpdatePaymentStatus: () => _updatePaymentStatus(
                  onUpdate: (paymentStatus) => _updatePaymentStatusOptimistic(paymentStatus, cubit),
                ),
                onDelete: _deleteInvoice,
              ),
            ],
          ),
        ),
        if (isGeneratingPdf)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري إنشاء PDF...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _editInvoice() {
    final isSales = widget.type == 'sale';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditInvoicePage(
          invoiceId: widget.invoiceId,
          isSales: isSales,
        ),
      ),
    );
  }

  void _updateInvoiceStatus({required Function(String newState) onUpdate}) {
    showDialog(
      context: context,
      builder: (dialogContext) => InvoiceStatusDialog(
        currentStatus: _getInvoiceStatus(),
        onUpdate: (newState) => onUpdate(newState),
      ),
    );
  }

  void _updatePaymentStatus({
    required Function(String paymentStatus) onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentStatusDialog(
        currentStatus: _getPaymentStatus(),
        onStatusChanged: (paymentStatus) => onUpdate(paymentStatus),
      ),
    );
  }

  /// Optimistic update for invoice status - UI first, then API
  Future<void> _updateInvoiceStatusOptimistic(String newState, InvoiceCubit cubit) async {
    log('Optimistic update: Invoice status to $newState');
    
    // 1. Save old state for rollback
    final oldInvoice = invoice;
    
    // 2. Update UI immediately (optimistic)
    setState(() {
      if (invoice is SalesInvoice) {
        final updatedStatus = InvoiceStatus.fromString(newState);
        invoice = (invoice as SalesInvoice).copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );
      } else if (invoice is PurchaseInvoice) {
        final updatedStatus = InvoiceStatus.fromString(newState);
        invoice = (invoice as PurchaseInvoice).copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );
      }
    });
    
    // 3. Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تحديث حالة الفاتورة...')),
    );
    
    try {
      // 4. Send to API
      if (oldInvoice is SalesInvoice) {
        final updatedStatus = InvoiceStatus.fromString(newState);
        final updatedInvoice = oldInvoice.copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );
        await cubit.updateSalesInvoice(updatedInvoice, optimisticUpdate: true);
      } else if (oldInvoice is PurchaseInvoice) {
        final updatedStatus = InvoiceStatus.fromString(newState);
        final updatedInvoice = oldInvoice.copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );
        await cubit.updatePurchaseInvoice(updatedInvoice, optimisticUpdate: true);
      }
      
      // 5. Success - keep the change
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الفاتورة بنجاح')),
      );
    } catch (e) {
      // 6. Error - rollback to old state
      log('Error updating invoice status: $e');
      setState(() {
        invoice = oldInvoice;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث حالة الفاتورة: ${e.toString()}')),
      );
    }
  }

  /// Optimistic update for payment status - UI first, then API
  Future<void> _updatePaymentStatusOptimistic(String paymentStatus, InvoiceCubit cubit) async {
    log('Optimistic update: Payment status to $paymentStatus');
    
    // 1. Save old state for rollback
    final oldInvoice = invoice;
    
    // 2. Update UI immediately (optimistic)
    setState(() {
      if (invoice is SalesInvoice) {
        final updatedStatus = PaymentStatus.fromString(paymentStatus);
        invoice = (invoice as SalesInvoice).copyWith(
          paymentStatus: updatedStatus,
          updatedAt: DateTime.now(),
        );
      } else if (invoice is PurchaseInvoice) {
        final updatedStatus = PaymentStatus.fromString(paymentStatus);
        invoice = (invoice as PurchaseInvoice).copyWith(
          paymentStatus: updatedStatus,
          updatedAt: DateTime.now(),
        );
      }
    });
    
    // 3. Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تحديث حالة الدفع...')),
    );
    
    try {
      // 4. Send to API
      if (oldInvoice is SalesInvoice) {
        await cubit.updateInvoicePaymentStatusWithBalance(
          oldInvoice,
          paymentStatus,
        );
      } else if (oldInvoice is PurchaseInvoice) {
        final updatedStatus = PaymentStatus.fromString(paymentStatus);
        final updatedInvoice = oldInvoice.copyWith(
          paymentStatus: updatedStatus,
          updatedAt: DateTime.now(),
        );
        await cubit.updatePurchaseInvoice(updatedInvoice, optimisticUpdate: true);
      }
      
      // 5. Success - keep the change
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الدفع بنجاح')),
      );
    } catch (e) {
      // 6. Error - rollback to old state
      log('Error updating payment status: $e');
      setState(() {
        invoice = oldInvoice;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث حالة الدفع: ${e.toString()}')),
      );
    }
  }

  void _deleteInvoice() {
    final cubit = context.read<InvoiceCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteInvoiceDialog(
        invoiceNumber: widget.invoiceId,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          setState(() {
            isDeleting = true;
          });
          try {
            if (widget.type == 'sale') {
              await cubit.deleteSalesInvoice(widget.invoiceId);
            } else {
              await cubit.deletePurchaseInvoice(widget.invoiceId);
            }
          } finally {
            if (mounted) {
              setState(() {
                isDeleting = false;
              });
            }
          }
        },
      ),
    );
  }

  void _generatePdf() async {
    try {
      setState(() {
        isGeneratingPdf = true;
      });
      final pdfService = PdfInvoiceService();
      final pdfFile = await pdfService.generateInvoicePdf(invoice, widget.type);

      await Printing.sharePdf(
        bytes: await pdfFile.save(),
        filename: 'invoice_${_getInvoiceNumber()}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إنشاء PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingPdf = false;
        });
      }
    }
  }

  // New helper methods for the new design
  String _formatDate(DateTime date) {
    // Using a simple date format without locale to avoid initialization issues
    final months = [
      "يناير",
      "فبراير",
      "مارس",
      "أبريل",
      "مايو",
      "يونيو",
      "يوليو",
      "أغسطس",
      "سبتمبر",
      "أكتوبر",
      "نوفمبر",
      "ديسمبر",
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<InvoiceItem> _getProductsList() {
    final items = _getItems();
    return items.map((item) {
      return InvoiceItem(
        unit: item.unit,
        measurement: item.measurement,
        productName: item.productName,
        quantity: item.quantity ?? 0,
        unitPrice: item.unitPrice ?? 0.0,
        purchasePrice: 0.0,
        totalPrice: (item.quantity ?? 0) * (item.unitPrice ?? 0.0),
        discountAmount: 0.0,
      );
    }).toList();
  }


    Color getStatusColor(String status) {
    return InvoiceStatus.fromString(status).getColor;
  }

  Color getPaymentStatusColor(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getColor;
  }

  String getStatusText(String status) {
    return InvoiceStatus.fromString(status).getArabicName;
  }

  String getPaymentStatusText(String paymentStatus) {
    return PaymentStatus.fromString(paymentStatus).getArabicName;
  }


  // Helper methods
  String _getInvoiceNumber() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).invoiceNumber;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).invoiceNumber;
    }
    return '';
  }

  String _getCustomerOrSupplierName() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).customerName ?? 'غير محدد';
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).supplierName ?? 'غير محدد';
    }
    return '';
  }

  DateTime _getInvoiceDate() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).invoiceDate;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).invoiceDate;
    }
    return DateTime.now();
  }

  String _getPaymentStatus() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).paymentStatus.name;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).paymentStatus.name;
    }
    return '';
  }

  String _getInvoiceStatus() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).status.name;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).status.name;
    }
    return '';
  }

  List _getItems() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).items;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).items;
    }
    return [];
  }

  double _getSubtotal() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).subtotal;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).subtotal;
    }
    return 0.0;
  }

  double _getDiscountAmount() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).discountAmount;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).discountAmount;
    }
    return 0.0;
  }

  double _getTotalAmount() {
    if (invoice is SalesInvoice) {
      return (invoice as SalesInvoice).totalAmount;
    } else if (invoice is PurchaseInvoice) {
      return (invoice as PurchaseInvoice).totalAmount;
    }
    return 0.0;
  }
}
