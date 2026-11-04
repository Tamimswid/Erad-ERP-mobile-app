import 'dart:developer' as dev;

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/core/services/pdf_invoice_service.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/core/widgets/app_period_selector.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';
import 'package:erad/features/customer_debts/presentation/widgets/unpaid_invoices_widget.dart';
import 'package:erad/features/customer_debts/presentation/widgets/payment_history_widget.dart';
import 'package:erad/features/debts/presentation/debts_types.dart';
import 'package:erad/features/debts/presentation/widgets/debt_detail_header.dart';
import 'package:erad/features/debts/presentation/widgets/debts_summary_card.dart';
import 'package:erad/features/debts/presentation/widgets/payment_modal_widget.dart';
import 'package:erad/features/invoices/presentation/pages/invoice_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحة تفاصيل العميل - نظام الديون والمدفوعات
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

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  static const int _pageSize = 10;

  final CustomerDebtRepository _repository = sl<CustomerDebtRepository>();
  final _supabase = Supabase.instance.client;
  DebtDetailTab _tab = DebtDetailTab.invoices;

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  double _totalInvoices = 0;
  double _totalPaid = 0;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  int _invoiceOffset = 0;
  bool _hasMoreInvoices = true;
  bool _isLoadingMoreInvoices = false;

  int _paymentOffset = 0;
  bool _hasMorePayments = true;
  bool _isLoadingMorePayments = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  List<InvoiceModel> get _invoiceModels {
    return _invoices.map((inv) => InvoiceModel.fromMap(inv)).toList();
  }

  List<PaymentModel> get _paymentModels {
    return _payments.map((payment) => PaymentModel.fromMap(payment)).toList();
  }

  double get _remainingDebt => _totalInvoices - _totalPaid;

  Future<void> _loadInitialData() async {
    await _refreshAll();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadTotals(),
      _loadInvoices(reset: true),
      _loadPayments(reset: true),
    ]);
  }

  Future<void> _loadTotals() async {
    final invoiceResult = await _repository.getCustomerInvoiceTotal(
      widget.customer.id,
    );
    final paymentResult = await _repository.getCustomerPaymentTotal(
      widget.customer.id,
    );
    if (!mounted) return;

    setState(() {
      invoiceResult.fold((_) {}, (total) => _totalInvoices = total);
      paymentResult.fold((_) {}, (total) => _totalPaid = total);
    });
  }

  Future<void> _loadInvoices({bool reset = false}) async {
    if (!reset && (!_hasMoreInvoices || _isLoadingMoreInvoices)) return;

    final offset = reset ? 0 : _invoiceOffset;
    if (mounted) setState(() => _isLoadingMoreInvoices = true);

    final result = await _repository.getCustomerInvoicesPage(
      widget.customer.id,
      offset: offset,
      limit: _pageSize,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoadingMoreInvoices = false);
        _showError('خطأ في تحميل الفواتير: ${failure.message}');
      },
      (page) {
        setState(() {
          _invoices = reset ? page.items : [..._invoices, ...page.items];
          _invoiceOffset = _invoices.length;
          _hasMoreInvoices = page.hasMore;
          _isLoadingMoreInvoices = false;
        });
      },
    );
  }

  Future<void> _loadPayments({bool reset = false}) async {
    if (!reset && (!_hasMorePayments || _isLoadingMorePayments)) return;

    final offset = reset ? 0 : _paymentOffset;
    if (mounted) setState(() => _isLoadingMorePayments = true);

    final result = await _repository.getCustomerPaymentsPage(
      widget.customer.id,
      offset: offset,
      limit: _pageSize,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoadingMorePayments = false);
        _showError('خطأ في تحميل المدفوعات: ${failure.message}');
      },
      (page) {
        setState(() {
          _payments = reset ? page.items : [..._payments, ...page.items];
          _paymentOffset = _payments.length;
          _hasMorePayments = page.hasMore;
          _isLoadingMorePayments = false;
        });
      },
    );
  }

  Future<void> _generateDebtPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final invoicesResult = await _repository.getCustomerInvoices(
        widget.customer.id,
      );
      final paymentsResult = await _repository.getCustomerPayments(
        widget.customer.id,
      );
      final invoices = invoicesResult.getOrElse(() => <Map<String, dynamic>>[]);
      final payments = paymentsResult.getOrElse(() => <Map<String, dynamic>>[]);
      if (invoices.isEmpty && payments.isEmpty) return;

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
        partyName: widget.customer.name,
        dateRangeLabel: '',
        invoices: invoices,
        payments: payments,
        isSupplier: false,
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'debt_${widget.customer.id}.pdf',
      );
    } catch (e) {
      dev.log('Debt PDF generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل إنشاء PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
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

    setState(() {
      _payments = [
        {
          'id': tempPaymentId,
          'user_id': '',
          'customer_id': widget.customer.id,
          'amount': amount,
          'payment_date': date,
          'payment_method': 'نقداً',
          'notes': note,
          'created_at': now,
          'isPending': true,
        },
        ..._payments,
      ];
      _totalPaid += amount;
    });

    _showSuccess('جاري معالجة المدفوعة...');

    try {
      final result = await _repository.addPayment(
        widget.customer.id,
        amount,
        note,
        date,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          setState(() {
            _payments = _payments
                .where((p) => p['id'] != tempPaymentId)
                .toList();
            _totalPaid -= amount;
          });
          _showError('فشل في إضافة المدفوعة: ${failure.message}');
        },
        (_) {
          if (!mounted) return;
          _showSuccess('تم تسجيل المدفوعة بنجاح: ${amount.toStringAsFixed(2)}');
          _loadTotals();
          _loadPayments(reset: true);
          sl<DataChangeNotifier>().notifyChanged(DataDomain.customerDebts);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _payments = _payments.where((p) => p['id'] != tempPaymentId).toList();
        _totalPaid -= amount;
      });
      _showError('خطأ غير متوقع: $e');
    }
  }

  Future<void> _deletePayment(String paymentId) async {
    final paymentIndex = _payments.indexWhere((p) => p['id'] == paymentId);
    if (paymentIndex == -1) return;

    final payment = _payments[paymentIndex];
    final amount = (payment['amount'] ?? 0.0).toDouble();

    setState(() {
      _payments = [..._payments]..removeAt(paymentIndex);
      _totalPaid -= amount;
    });

    try {
      final result = await _repository.deletePayment(
        paymentId,
        widget.customer.id,
        amount,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          _restorePayment(paymentIndex, payment);
          setState(() => _totalPaid += amount);
          _showError('فشل في حذف المدفوعة: ${failure.message}');
        },
        (_) {
          if (!mounted) return;
          _showSuccess('تم حذف المدفوعة بنجاح');
          _loadTotals();
          _loadPayments(reset: true);
          sl<DataChangeNotifier>().notifyChanged(DataDomain.customerDebts);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _restorePayment(paymentIndex, payment);
      setState(() => _totalPaid += amount);
      _showError('خطأ غير متوقع: $e');
    }
  }

  void _restorePayment(int index, Map<String, dynamic> payment) {
    final restored = [..._payments];
    restored.insert(index.clamp(0, restored.length), payment);
    setState(() => _payments = restored);
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
        appBar: AppBar(title: Text(widget.customer.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DebtDetailHeader(
                name: widget.customer.name,
                phone: widget.customer.phone,
                onPdf: _generateDebtPdf,
                isGeneratingPdf: _isGeneratingPdf,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DebtsSummaryCard(
                title: 'المتبقي على الحساب',
                totalDebt: _remainingDebt,
                totalInvoices: _totalInvoices,
                totalPaid: _totalPaid,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppPeriodSelector<DebtDetailTab>(
                expanded: true,
                options: [
                  AppPeriodOption(
                    value: DebtDetailTab.invoices,
                    label:
                        'الفواتير (${_invoices.length}${_hasMoreInvoices ? '+' : ''})',
                  ),
                  AppPeriodOption(
                    value: DebtDetailTab.payments,
                    label:
                        'المدفوعات (${_payments.length}${_hasMorePayments ? '+' : ''})',
                  ),
                ],
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tab == DebtDetailTab.invoices
                  ? _buildInvoicesTab()
                  : _buildPaymentsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    final invoices = _invoiceModels;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              icon: sc.LucideIcons.clock,
              title: 'فواتير الديون',
              count: invoices.length,
              hasMore: _hasMoreInvoices,
            ),
          ),
          if (invoices.isEmpty)
            SliverToBoxAdapter(
              child: _isLoadingMoreInvoices
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildEmptyCard('لا توجد فواتير ديون'),
            )
          else
            AppPaginationSliverList(
              itemCount: invoices.length,
              hasMore: _hasMoreInvoices,
              isLoadingMore: _isLoadingMoreInvoices,
              onLoadMore: () => _loadInvoices(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separator: const SizedBox(height: 8),
              bottomSpace: 24,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return UnpaidInvoiceRow(
                  invoice: invoice,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailPage(
                        invoiceId: invoice.id,
                        type: 'sale',
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final payments = _paymentModels;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              icon: sc.LucideIcons.history,
              title: 'سجل المدفوعات',
              count: payments.length,
              hasMore: _hasMorePayments,
              onAdd: widget.isLocal ? null : _showPaymentModal,
            ),
          ),
          if (payments.isEmpty)
            SliverToBoxAdapter(
              child: _isLoadingMorePayments
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildEmptyCard('لا توجد مدفوعات'),
            )
          else
            AppPaginationSliverList(
              itemCount: payments.length,
              hasMore: _hasMorePayments,
              isLoadingMore: _isLoadingMorePayments,
              onLoadMore: () => _loadPayments(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separator: const SizedBox(height: 8),
              bottomSpace: 24,
              itemBuilder: (context, index) {
                return PaymentHistoryRow(
                  payment: payments[index],
                  onDeletePayment: _deletePayment,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required bool hasMore,
    VoidCallback? onAdd,
  }) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.foreground,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.muted,
              borderRadius: theme.borderRadiusSm,
            ),
            child: Text(
              '$count${hasMore ? '+' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.mutedForeground,
              ),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 8),
            sc.Button(
              style: const sc.ButtonStyle.secondary(),
              onPressed: onAdd,
              leading: const Icon(sc.LucideIcons.plus, size: 14),
              child: const Text(
                'إضافة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: sc.Card(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sc.LucideIcons.inbox,
                size: 18,
                color: scheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(fontSize: 13, color: scheme.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
