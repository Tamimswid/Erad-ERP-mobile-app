import 'dart:async';
import 'dart:developer' as dev;

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';
import 'package:erad/features/customer_debts/presentation/widgets/customer_detail_header_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/customer_summary_cards_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/unpaid_invoices_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/payment_history_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/payment_modal_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحة تفاصيل العميل - نظام الديون والمدفوعات
/// تعرض الفواتير المستحقة والمدفوعات مع تحديثات فورية
class CustomerDetailPage extends StatefulWidget {
  final CustomerDebtModel customer;
  final bool isLocal;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    this.isLocal = false,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> with SingleTickerProviderStateMixin {
  final CustomerDebtRepository _repository = sl<CustomerDebtRepository>();
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  bool _showAllInvoices = false;
  bool _showAllPayments = false;
  static const int _initialDisplayCount = 5;

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

  List<InvoiceModel> get _invoiceModels {
    return _invoices
        .where((inv) => inv['payment_status'] == 'debt')
        .map((inv) => InvoiceModel.fromMap(inv))
        .toList();
  }

  /// الفواتير المعروضة (الأول 5 أو جميعها)
  List<InvoiceModel> get _displayedInvoices {
    final all = _invoiceModels;
    if (_showAllInvoices || all.length <= _initialDisplayCount) {
      return all;
    }
    return all.take(_initialDisplayCount).toList();
  }

  /// هل يوجد فواتير مخفية؟
  bool get _hasMoreInvoices => _invoiceModels.length > _initialDisplayCount;

  /// تحويل بيانات المدفوعات إلى نماذج للعرض (جميع المدفوعات)
  List<PaymentModel> get _paymentModels {
    return _payments
        .map((payment) => PaymentModel.fromMap(payment))
        .toList();
  }

  /// المدفوعات المعروضة (الأول 5 أو جميعها)
  List<PaymentModel> get _displayedPayments {
    final all = _paymentModels;
    if (_showAllPayments || all.length <= _initialDisplayCount) {
      return all;
    }
    return all.take(_initialDisplayCount).toList();
  }

  /// هل يوجد مدفوعات مخفية؟
  bool get _hasMorePayments => _paymentModels.length > _initialDisplayCount;

  /// إجمالي الفواتير (المفلترة)
  double get _totalInvoices =>
      _invoiceModels.fold(0.0, (sum, inv) => sum + inv.totalAmount);

  /// إجمالي المدفوعات (المفلترة)
  double get _totalPaid =>
      _paymentModels.fold(0.0, (sum, p) => sum + p.amount);

  /// إجمالي المتبقي (إجمالي الفواتير - إجمالي المدفوعات)
  double get _remainingDebt => _totalInvoices - _totalPaid;

  /// تبديل عرض جميع الفواتير/المدفوعات
  void _toggleShowAllInvoices() {
    if (mounted) {
      setState(() {
        _showAllInvoices = !_showAllInvoices;
      });
    }
  }

  void _toggleShowAllPayments() {
    if (mounted) {
      setState(() {
        _showAllPayments = !_showAllPayments;
      });
    }
  }

  /// إلغاء جميع الاشتراكات
  void _cancelSubscriptions() {
    _invoicesSubscription?.cancel();
    _paymentsSubscription?.cancel();
  }

  /// تهيئة البث الفوري من Supabase
  void _initializeRealTimeStreams() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;

    final customerId = widget.customer.id;

    // بث الفواتير - الاستماع للتغييرات الفورية
    _invoicesSubscription = _supabase
        .from('sales_invoices')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final filtered = data
              .where((inv) =>
                  inv['user_id'] == userId && inv['customer_id'] == customerId)
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
            dev.log('CustomerDetail: invoice stream error - $error');
          },
        );

    // بث المدفوعات - الاستماع للتغييرات الفورية (only customer payments)
    _paymentsSubscription = _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final filtered = data
              .where((p) =>
                  p['user_id'] == userId && 
                  p['customer_id'] == customerId &&
                  p['payment_type'] == 'customer')
              .toList();
          return List<Map<String, dynamic>>.from(filtered);
        })
        .listen(
          (payments) {
            if (mounted) {
              setState(() {
                final streamIds = payments.map((p) => p['id']).toSet();
                final keptLocals = _payments.where((p) =>
                    (p['id'] as String).startsWith('pending_') &&
                    !streamIds.contains(p['id']));
                _payments = [...keptLocals, ...payments];
              });
            }
          },
          onError: (error) {
            dev.log('CustomerDetail: payment stream error - $error');
          },
        );
  }

  /// تحميل البيانات الأولية
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

  /// تحميل الفواتير
  Future<void> _loadInvoices() async {
    final result = await _repository.getCustomerInvoices(widget.customer.id);
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

  /// تحميل المدفوعات
  Future<void> _loadPayments() async {
    final result = await _repository.getCustomerPayments(widget.customer.id);
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

  /// إضافة مدفوعة جديدة - نمط التحديث المتفائل
  Future<void> _addPayment(double amount, String date, String? note) async {
    if (amount <= 0) {
      _showError('المبلغ يجب أن يكون أكبر من صفر');
      return;
    }

    if (amount > _remainingDebt) {
      _showError('المبلغ أكبر من الديون المتبقية');
      return;
    }

    // إنشاء معرف مؤقت للمدفوعة
    final tempPaymentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    // 1. تحديث الواجهة فوراً (نمط متفائل)
    if (mounted) {
      setState(() {
        _payments.insert(0, {
          'id': tempPaymentId,
          'user_id': '',
          'customer_id': widget.customer.id,
          'amount': amount,
          'payment_date': date,
          'payment_method': 'نقداً',
          'notes': note,
          'created_at': now,
          'isPending': true, // علامة أنها قيد المعالجة
        });
      });
    }

    _showSuccess('جاري معالجة المدفوعة...');

    try {
      // 2. إرسال للخادم
      final result =
          await _repository.addPayment(widget.customer.id, amount, note, date);

      result.fold(
        (failure) {
          // 3. في حالة الخطأ - التراجع عن التحديث
          if (mounted) {
            _rollbackPayment(tempPaymentId, amount);
            _showError('فشل في إضافة المدفوعة: ${failure.message}');
          }
        },
        (_) {
          // 4. نجاح - إزالة علامة المعلقة
          if (mounted) {
            setState(() {
              final idx = _payments.indexWhere((p) => p['id'] == tempPaymentId);
              if (idx != -1) {
                _payments[idx] = Map<String, dynamic>.from(_payments[idx])
                  ..remove('isPending');
              }
            });
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

  /// التراجع عن إضافة مدفوعة في حالة الخطأ
  void _rollbackPayment(String tempId, double amount) {
    if (mounted) {
      setState(() {
        _payments.removeWhere((p) => p['id'] == tempId);
      });
    }
  }

  /// حذف مدفوعة - نمط التحديث المتفائل
  Future<void> _deletePayment(String paymentId) async {
    // البحث عن المدفوعة المحلياً
    final paymentIndex = _payments.indexWhere((p) => p['id'] == paymentId);
    if (paymentIndex == -1) return;

    final payment = _payments[paymentIndex];
    final amount = (payment['amount'] ?? 0.0).toDouble();

    // 1. تحديث الواجهة فوراً
    if (mounted) {
      setState(() {
        _payments.removeAt(paymentIndex);
      });
    }

    try {
      // 2. إرسال للخادم
      final result =
          await _repository.deletePayment(paymentId, widget.customer.id, amount);

      result.fold(
        (failure) {
          // 3. في حالة الخطأ - استعادة المدفوعة
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

  /// استعادة مدفوعة محذوفة في حالة الخطأ
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

  /// عرض نموذج إضافة مدفوعة
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

  /// عرض رسالة نجاح
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

  /// عرض رسالة خطأ
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
    // عرض مؤشر التحميل أثناء تحميل البيانات
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
            widget.customer.name,
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
                  CustomerDetailHeaderWidget(
                    customerName: widget.customer.name,
                    customerPhone: widget.customer.phone ?? '',
                    onBackPressed: () => Navigator.pop(context),
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
            invoices: _displayedInvoices,
            onQuickPay: widget.isLocal ? (_) {} : (invoiceId) => _showPaymentModal(),
          ),
          if (_hasMoreInvoices)
            _buildShowMoreButton(
              isShowingAll: _showAllInvoices,
              totalCount: _invoiceModels.length,
              displayedCount: _displayedInvoices.length,
              onToggle: _toggleShowAllInvoices,
              itemType: 'فاتورة',
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
            payments: _displayedPayments,
            onAddPayment: widget.isLocal ? null : _showPaymentModal,
            onDeletePayment: _deletePayment,
          ),
          if (_hasMorePayments)
            _buildShowMoreButton(
              isShowingAll: _showAllPayments,
              totalCount: _paymentModels.length,
              displayedCount: _displayedPayments.length,
              onToggle: _toggleShowAllPayments,
              itemType: 'دفعة',
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// زر عرض المزيد/أقل
  Widget _buildShowMoreButton({
    required bool isShowingAll,
    required int totalCount,
    required int displayedCount,
    required VoidCallback onToggle,
    required String itemType,
  }) {
    final remainingCount = totalCount - displayedCount;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
        onPressed: onToggle,
        icon: Icon(
          isShowingAll ? Icons.expand_less : Icons.expand_more,
          color: AppColors.primary,
        ),
        label: Text(
          isShowingAll
              ? 'إظهار أقل'
              : 'عرض $remainingCount $itemType أخرى',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
