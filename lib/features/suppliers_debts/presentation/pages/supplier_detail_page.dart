import 'dart:async';
import 'dart:developer' as dev;

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/services/pdf_invoice_service.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/repositories/supplier_debt_repository.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/supplier_detail_header_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/customer_summary_cards_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/unpaid_invoices_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/payment_history_widget.dart';
import 'package:erad/features/suppliers_debts/presentation/widgets/payment_modal_widget.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierDetailPage extends StatefulWidget {
  final SupplierDebtModel supplier;
  final bool isLocal;

  const SupplierDetailPage({
    super.key,
    required this.supplier,
    this.isLocal = false,
  });

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> with SingleTickerProviderStateMixin {
  final SupplierDebtRepository _repository = sl<SupplierDebtRepository>();
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  StreamSubscription<List<Map<String, dynamic>>>? _invoicesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _paymentsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeRealTimeStreams();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cancelSubscriptions();
    super.dispose();
  }

  List<PurchaseInvoiceModel> get _invoiceModels {
    return _invoices
        .where((inv) => inv['payment_status'] == 'debt')
        .map((inv) => PurchaseInvoiceModel.fromMap(inv))
        .toList();
  }

  List<SupplierPaymentModel> get _paymentModels {
    return _payments
        .map((payment) => SupplierPaymentModel.fromMap(payment))
        .toList();
  }

  double get _totalInvoices =>
      _invoiceModels.fold(0.0, (sum, inv) => sum + inv.totalAmount);

  double get _totalPaid =>
      _paymentModels.fold(0.0, (sum, p) => sum + p.amount);

  double get _remainingDebt => _totalInvoices - _totalPaid;

  Future<void> _generateDebtPdf() async {
    if (_invoices.isEmpty && _payments.isEmpty) return;
    setState(() => _isGeneratingPdf = true);
    try {
      String companyName = '';
      final userId = await UserService.getUserId();
      if (userId != null) {
        final profile = await _supabase
            .from('profiles')
            .select('business_name')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null) {
          companyName = (profile['business_name'] as String?) ?? '';
        }
      }

      final pdfService = PdfInvoiceService();
      final pdf = await pdfService.generateDebtPdf(
        companyName: companyName,
        partyName: widget.supplier.name,
        dateRangeLabel: '',
        invoices: _invoices,
        payments: _payments,
        isSupplier: true,
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'debt_${widget.supplier.id}.pdf',
      );
    } catch (e) {
      dev.log('Debt PDF generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _cancelSubscriptions() {
    _invoicesSubscription?.cancel();
    _paymentsSubscription?.cancel();
  }

  void _initializeRealTimeStreams() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;

    final supplierId = widget.supplier.id;

    _invoicesSubscription = _supabase
        .from('purchase_invoices')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final filtered = data
              .where((inv) =>
                  inv['user_id'] == userId && inv['supplier_id'] == supplierId)
              .toList();
          return List<Map<String, dynamic>>.from(filtered);
        })
        .listen(
          (invoices) {
            if (mounted) {
              setState(() {
                _invoices = invoices;
              });
            }
          },
          onError: (error) {
            _showError('خطأ في تحديث الفواتير: $error');
          },
        );

    _paymentsSubscription = _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final filtered = data
              .where((p) =>
                  p['user_id'] == userId && 
                  p['supplier_id'] == supplierId &&
                  p['payment_type'] == 'supplier')
              .toList();
          return List<Map<String, dynamic>>.from(filtered);
        })
        .listen(
          (payments) {
            if (mounted) {
              setState(() {
                _payments = payments;
              });
            }
          },
          onError: (error) {
            _showError('خطأ في تحديث المدفوعات: $error');
          },
        );
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadInvoices();
      await _loadPayments();
    } catch (e) {
      _showError('خطأ في تحميل البيانات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInvoices() async {
    final result = await _repository.getSupplierInvoices(widget.supplier.id);
    result.fold(
      (failure) => _showError('خطأ في تحميل الفواتير: ${failure.message}'),
      (invoices) {
        if (mounted) {
          setState(() {
            _invoices = invoices;
          });
        }
      },
    );
  }

  Future<void> _loadPayments() async {
    final result = await _repository.getSupplierPayments(widget.supplier.id);
    result.fold(
      (failure) => _showError('خطأ في تحميل المدفوعات: ${failure.message}'),
      (payments) {
        if (mounted) {
          setState(() {
            _payments = payments;
          });
        }
      },
    );
  }

  Future<void> _addPayment(double amount, String date, String? note) async {
    if (amount <= 0) {
      _showError('المبلغ يجب أن يكون أكبر من صفر');
      return;
    }

    if (amount > _remainingDebt) {
      _showError('المبلغ أكبر من الديون المتبقية');
      return;
    }

    final tempPaymentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    if (mounted) {
      setState(() {
        _payments.insert(0, {
          'id': tempPaymentId,
          'user_id': '',
          'supplier_id': widget.supplier.id,
          'amount': amount,
          'payment_date': date,
          'payment_method': 'نقداً',
          'notes': note,
          'created_at': now,
          'isPending': true,
        });
      });
    }

    _showSuccess('جاري معالجة المدفوعة...');

    try {
      final result =
          await _repository.addPayment(widget.supplier.id, amount, note, date);

      result.fold(
        (failure) {
          if (mounted) {
            _rollbackPayment(tempPaymentId, amount);
            _showError('فشل في إضافة المدفوعة: ${failure.message}');
          }
        },
        (_) {
          if (mounted) {
            _showSuccess('تم تسجيل المدفوعة بنجاح: ${amount.toStringAsFixed(2)}');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _rollbackPayment(tempPaymentId, amount);
        _showError('خطأ غير متوقع: $e');
      }
    }
  }

  void _rollbackPayment(String tempId, double amount) {
    if (mounted) {
      setState(() {
        _payments.removeWhere((p) => p['id'] == tempId);
      });
    }
  }

  Future<void> _deletePayment(String paymentId) async {
    final paymentIndex = _payments.indexWhere((p) => p['id'] == paymentId);
    if (paymentIndex == -1) return;

    final payment = _payments[paymentIndex];
    final amount = (payment['amount'] ?? 0.0).toDouble();

    if (mounted) {
      setState(() {
        _payments.removeAt(paymentIndex);
      });
    }

    try {
      final result =
          await _repository.deletePayment(paymentId, widget.supplier.id, amount);

      result.fold(
        (failure) {
          if (mounted) {
            _restorePayment(paymentIndex, payment, amount);
            _showError('فشل في حذف المدفوعة: ${failure.message}');
          }
        },
        (_) {
          if (mounted) {
            _showSuccess('تم حذف المدفوعة بنجاح');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _restorePayment(paymentIndex, payment, amount);
        _showError('خطأ غير متوقع: $e');
      }
    }
  }

  void _restorePayment(int index, Map<String, dynamic> payment, double amount) {
    if (mounted) {
      setState(() {
        if (index >= _payments.length) {
          _payments.add(payment);
        } else {
          _payments.insert(index, payment);
        }
      });
    }
  }

  void _showPaymentModal() {
    showDialog(
      context: context,
      builder: (context) => PaymentModalWidget(
        remainingDebt: _remainingDebt,
        onPaymentSubmit: (amount, date, note) {
          Navigator.pop(context);
          _addPayment(amount, date, note);
        },
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.supplier.name,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل البيانات...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SupplierDetailHeaderWidget(
                    supplierName: widget.supplier.name,
                    supplierPhone: widget.supplier.phone ?? '',
                    onBackPressed: () => Navigator.pop(context),
                    onPdfPressed: _isGeneratingPdf ? null : _generateDebtPdf,
                  ),
                  const SizedBox(height: 16),
                  CustomerSummaryCardsWidget(
                    totalInvoices: _totalInvoices,
                    totalPaid: _totalPaid,
                    remainingDebt: _remainingDebt,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: [
                        Tab(text: 'الفواتير (${_invoiceModels.length})'),
                        Tab(text: 'المدفوعات (${_paymentModels.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvoicesTab(),
                    _buildPaymentsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          UnpaidInvoicesWidget(
            invoices: _invoiceModels,
            onQuickPay: widget.isLocal ? (_) {} : (invoiceId) => _showPaymentModal(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          PaymentHistoryWidget(
            payments: _paymentModels,
            onAddPayment: widget.isLocal ? null : _showPaymentModal,
            onDeletePayment: _deletePayment,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}