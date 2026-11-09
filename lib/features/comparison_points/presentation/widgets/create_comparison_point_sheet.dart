import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';
import 'package:erad/features/comparison_points/data/repositories/comparison_point_repository.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// إنشاء نقطة مطابقة: آخر فاتورة في الفترة هي حد النقطة
class CreateComparisonPointSheet {
  CreateComparisonPointSheet._();

  static Future<bool?> show(
    BuildContext context, {
    required ComparisonPartyType partyType,
    required String partyId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLg),
        ),
      ),
      builder: (_) => _CreatePointSheet(partyType: partyType, partyId: partyId),
    );
  }
}

class _CreatePointSheet extends StatefulWidget {
  final ComparisonPartyType partyType;
  final String partyId;

  const _CreatePointSheet({required this.partyType, required this.partyId});

  @override
  State<_CreatePointSheet> createState() => _CreatePointSheetState();
}

class _CreatePointSheetState extends State<_CreatePointSheet> {
  final ComparisonPointRepository _repository = sl<ComparisonPointRepository>();
  final _labelController = TextEditingController();

  List<Map<String, dynamic>> _invoices = [];
  int? _selectedIndex;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.getUnassignedInvoices(
      partyType: widget.partyType,
      partyId: widget.partyId,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
      (invoices) {
        setState(() {
          _invoices = invoices;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _submit() async {
    final index = _selectedIndex;
    if (index == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final label = _labelController.text.trim();
    final result = await _repository.createPoint(
      partyType: widget.partyType,
      partyId: widget.partyId,
      anchorInvoiceId: _invoices[index]['invoice_id'] as String,
      label: label.isEmpty ? null : label,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _error = failure.message;
        });
      },
      (_) {
        Navigator.pop(context, true);
      },
    );
  }

  double _amount(Map<String, dynamic> invoice) {
    final value = invoice['total_amount'];
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'نقطة مطابقة جديدة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(sc.LucideIcons.x, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              Text(
                'اختر آخر فاتورة في الفترة: تُضاف كل الفواتير حتى هذه الفاتورة '
                'وكل الدفعات غير المرتبطة حتى لحظة الإنشاء.',
                style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              Flexible(child: _buildInvoiceList()),
              const Divider(height: 1, color: AppColors.divider),
              if (_selectedIndex != null) ...[
                const SizedBox(height: 12),
                _buildSelectionSummary(),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'اسم النقطة (اختياري)',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              if (_error != null && !_isLoading && _invoices.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: sc.Button(
                      alignment: Alignment.center,
                      style: const sc.ButtonStyle.outline(),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: sc.Button(
                      alignment: Alignment.center,
                      style: const sc.ButtonStyle.primary(),
                      onPressed: _selectedIndex == null || _isSaving
                          ? null
                          : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إنشاء'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              sc.LucideIcons.circleCheck,
              size: 28,
              color: AppColors.success,
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'لا توجد فواتير غير مرتبطة بنقطة مطابقة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              sc.Button(
                alignment: Alignment.center,
                style: const sc.ButtonStyle.outline(),
                onPressed: _loadInvoices,
                child: const Text('حاول ثانية'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _invoices.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        final isSelected = _selectedIndex == index;
        final scheme = sc.Theme.of(context).colorScheme;

        return InkWell(
          onTap: _isSaving
              ? null
              : () => setState(() => _selectedIndex = index),
          child: Container(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? sc.LucideIcons.circleCheck
                      : sc.LucideIcons.circleDot,
                  size: 18,
                  color: isSelected ? scheme.primary : scheme.mutedForeground,
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
                        '${invoice['invoice_date'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppUtils.formatNumber(_amount(invoice))} ${NumberFormatter.getCurrencySymbol()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.moneyOut,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionSummary() {
    final index = _selectedIndex!;
    final count = index + 1;
    final total = _invoices
        .take(count)
        .fold<double>(0, (sum, i) => sum + _amount(i));
    final scheme = sc.Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.muted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Row(
        children: [
          Icon(sc.LucideIcons.receipt, size: 16, color: scheme.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count فاتورة متضمنة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.foreground,
              ),
            ),
          ),
          Text(
            '${AppUtils.formatNumber(total)} ${NumberFormatter.getCurrencySymbol()}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.moneyOut,
            ),
          ),
        ],
      ),
    );
  }
}
