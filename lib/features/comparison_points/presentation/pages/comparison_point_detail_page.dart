import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/core/widgets/app_section_header.dart';
import 'package:erad/core/widgets/app_stat_tile.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';
import 'package:erad/features/comparison_points/data/repositories/comparison_point_repository.dart';
import 'package:erad/features/invoices/presentation/pages/invoice_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// فواتير ومدفوعات نقطة مطابقة واحدة
class ComparisonPointDetailPage extends StatefulWidget {
  final ComparisonPointModel point;

  const ComparisonPointDetailPage({super.key, required this.point});

  @override
  State<ComparisonPointDetailPage> createState() =>
      _ComparisonPointDetailPageState();
}

class _ComparisonPointDetailPageState extends State<ComparisonPointDetailPage> {
  final ComparisonPointRepository _repository = sl<ComparisonPointRepository>();

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;

  ComparisonPointModel get _point => widget.point;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final invoicesResult = await _repository.getPointInvoices(_point.id);
    final paymentsResult = await _repository.getPointPayments(_point.id);
    if (!mounted) return;

    var invoices = _invoices;
    var payments = _payments;
    String? error;
    invoicesResult.fold(
      (failure) {
        error = failure.message;
      },
      (value) {
        invoices = value;
      },
    );
    paymentsResult.fold(
      (failure) {
        error ??= failure.message;
      },
      (value) {
        payments = value;
      },
    );

    setState(() {
      _invoices = invoices;
      _payments = payments;
      _isLoading = false;
      _error = error;
    });
  }

  double _amount(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  String _date(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _money(double value) =>
      '${AppUtils.formatNumber(value)} ${NumberFormatter.getCurrencySymbol()}';

  void _openInvoice(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoiceId: invoice['invoice_id'] as String,
          type: invoice['invoice_type'] == 'purchase' ? 'purchase' : 'sale',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_point.displayName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildPointInfo(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          _buildSummary(),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          AppSectionHeader(
            title: 'الفواتير',
            subtitle: '${_invoices.length} فاتورة حتى هذه النقطة',
          ),
          const SizedBox(height: 4),
          if (_invoices.isEmpty)
            _buildEmptyLine('لا توجد فواتير في هذه النقطة')
          else
            for (var i = 0; i < _invoices.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              _buildInvoiceRow(_invoices[i]),
            ],
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          AppSectionHeader(
            title: 'الدفعات',
            subtitle: '${_payments.length} دفعة حتى هذه النقطة',
          ),
          const SizedBox(height: 4),
          if (_payments.isEmpty)
            _buildEmptyLine('لا توجد دفعات في هذه النقطة')
          else
            for (var i = 0; i < _payments.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              _buildPaymentRow(_payments[i]),
            ],
          if (_point.notes != null && _point.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'ملاحظات', subtitle: _point.notes),
          ],
        ],
      ),
    );
  }

  Widget _buildPointInfo() {
    final scheme = sc.Theme.of(context).colorScheme;
    final anchor = _point.anchorInvoiceNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _point.partyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.foreground,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _point.isStart ? 'نقطة البداية' : 'النقطة ${_point.sequenceNo}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          anchor == null
              ? 'تبدأ من أقدم فاتورة دين وأقدم دفعة · ${_date(_point.createdAt)}'
              : 'حتى الفاتورة $anchor · ${_date(_point.createdAt)}',
          style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final isDebt = _point.balance > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppStatTile(
            label: 'إجمالي الفواتير',
            value: _money(_point.invoiceTotal),
            valueColor: AppColors.moneyOut,
            icon: sc.LucideIcons.receipt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatTile(
            label: 'إجمالي الدفعات',
            value: _money(_point.paymentTotal),
            valueColor: AppColors.moneyIn,
            icon: sc.LucideIcons.banknote,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatTile(
            label: 'الرصيد',
            value: _money(_point.balance),
            valueColor: isDebt ? AppColors.moneyOut : AppColors.moneyIn,
            icon: sc.LucideIcons.scale,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(Map<String, dynamic> invoice) {
    final scheme = sc.Theme.of(context).colorScheme;
    final isDeleted = invoice['invoice_deleted_at'] != null;
    final date = '${invoice['invoice_date'] ?? ''}';

    return InkWell(
      onTap: () => _openInvoice(invoice),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              sc.LucideIcons.fileText,
              size: 16,
              color: scheme.mutedForeground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${invoice['invoice_number'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDeleted ? '$date · محذوفة' : date,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDeleted
                          ? AppColors.error
                          : scheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _money(_amount(invoice['total_amount'])),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.moneyOut,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المتبقي ${AppUtils.formatNumber(_amount(invoice['remaining_amount']))}',
                  style: TextStyle(fontSize: 11, color: scheme.mutedForeground),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              sc.LucideIcons.chevronLeft,
              size: 16,
              color: scheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    final scheme = sc.Theme.of(context).colorScheme;
    final notes = (payment['notes'] ?? '') as String;
    final date = '${payment['payment_date'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            sc.LucideIcons.arrowDownLeft,
            size: 16,
            color: AppColors.moneyIn,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date,
                  style: TextStyle(fontSize: 13, color: scheme.foreground),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(_amount(payment['amount'])),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.moneyIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLine(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        const Icon(
          sc.LucideIcons.circleAlert,
          size: 28,
          color: AppColors.error,
        ),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: sc.Button(
            alignment: Alignment.center,
            style: const sc.ButtonStyle.outline(),
            onPressed: _load,
            child: const Text('حاول ثانية'),
          ),
        ),
      ],
    );
  }
}
