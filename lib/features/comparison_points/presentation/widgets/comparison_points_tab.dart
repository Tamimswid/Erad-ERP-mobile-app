import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';
import 'package:erad/features/comparison_points/data/repositories/comparison_point_repository.dart';
import 'package:erad/features/comparison_points/presentation/pages/comparison_point_detail_page.dart';
import 'package:erad/features/comparison_points/presentation/widgets/create_comparison_point_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// نقاط المطابقة لطرف واحد: القائمة + إنشاء نقطة جديدة
class ComparisonPointsTab extends StatefulWidget {
  final ComparisonPartyType partyType;
  final String partyId;
  final String partyName;
  final bool isLocal;

  const ComparisonPointsTab({
    super.key,
    required this.partyType,
    required this.partyId,
    required this.partyName,
    this.isLocal = false,
  });

  @override
  State<ComparisonPointsTab> createState() => _ComparisonPointsTabState();
}

class _ComparisonPointsTabState extends State<ComparisonPointsTab> {
  final ComparisonPointRepository _repository = sl<ComparisonPointRepository>();

  List<ComparisonPointModel> _points = [];
  int _unassignedCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isLocal) _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    await _repository.ensureStartPoint(
      partyType: widget.partyType,
      partyId: widget.partyId,
    );

    final pointsResult = await _repository.getPoints(
      partyType: widget.partyType,
      partyId: widget.partyId,
    );
    final unassignedResult = await _repository.getUnassignedInvoices(
      partyType: widget.partyType,
      partyId: widget.partyId,
    );
    if (!mounted) return;

    var points = _points;
    var unassignedCount = _unassignedCount;
    String? error;
    pointsResult.fold(
      (failure) {
        error = failure.message;
      },
      (value) {
        points = value;
      },
    );
    unassignedResult.fold(
      (failure) {
        error ??= failure.message;
      },
      (value) {
        unassignedCount = value.length;
      },
    );

    setState(() {
      _points = points;
      _unassignedCount = unassignedCount;
      _isLoading = false;
      _error = error;
    });
  }

  Future<void> _openCreateSheet() async {
    final created = await CreateComparisonPointSheet.show(
      context,
      partyType: widget.partyType,
      partyId: widget.partyId,
    );
    if (created != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إنشاء نقطة المطابقة'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    await _load(silent: true);
  }

  void _openPoint(ComparisonPointModel point) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComparisonPointDetailPage(point: point),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocal) return _buildOfflineNotice();
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHeader(),
          _buildUnassignedNotice(),
          if (_points.isEmpty)
            _buildEmptyState()
          else
            for (var i = 0; i < _points.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              _PointRow(point: _points[i], onTap: () => _openPoint(_points[i])),
            ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(
            sc.LucideIcons.milestone,
            size: 16,
            color: scheme.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'نقاط المطابقة',
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
              '${_points.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          sc.Button(
            alignment: Alignment.center,
            style: const sc.ButtonStyle.secondary(),
            onPressed: _unassignedCount == 0 ? null : _openCreateSheet,
            leading: const Icon(sc.LucideIcons.plus, size: 14),
            child: const Text(
              'نقطة جديدة',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedNotice() {
    final hasUnassigned = _unassignedCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            hasUnassigned
                ? sc.LucideIcons.circleAlert
                : sc.LucideIcons.circleCheck,
            size: 14,
            color: hasUnassigned ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasUnassigned
                  ? '$_unassignedCount فاتورة غير مرتبطة بنقطة مطابقة'
                  : 'كل فواتير الديون مرتبطة بنقاط المطابقة',
              style: TextStyle(
                fontSize: 12,
                color: hasUnassigned
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sc.LucideIcons.inbox, size: 32, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'لا توجد نقاط مطابقة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'تُنشأ نقطة البداية تلقائياً مع أول فاتورة دين.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sc.LucideIcons.wifiOff,
            size: 32,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'نقاط المطابقة غير متاحة دون اتصال',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'اتصل بالإنترنت لعرض النقاط وإنشائها.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            sc.LucideIcons.circleAlert,
            size: 28,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          sc.Button(
            alignment: Alignment.center,
            style: const sc.ButtonStyle.outline(),
            onPressed: _load,
            child: const Text('حاول ثانية'),
          ),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final ComparisonPointModel point;
  final VoidCallback onTap;

  const _PointRow({required this.point, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;
    final isDebt = point.balance > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.muted,
                borderRadius: theme.borderRadiusSm,
              ),
              child: Text(
                '${point.sequenceNo}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.foreground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          point.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.foreground,
                          ),
                        ),
                      ),
                      if (point.isStart) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.muted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'البداية',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scheme.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    point.anchorInvoiceNumber == null
                        ? 'أقدم فاتورة وأقدم دفعة'
                        : 'حتى الفاتورة ${point.anchorInvoiceNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${point.invoiceCount} فاتورة · ${point.paymentCount} دفعة',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppUtils.formatNumber(point.balance)} ${NumberFormatter.getCurrencySymbol()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDebt ? AppColors.moneyOut : AppColors.moneyIn,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDebt ? 'المتبقي' : 'مسدد',
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
}
