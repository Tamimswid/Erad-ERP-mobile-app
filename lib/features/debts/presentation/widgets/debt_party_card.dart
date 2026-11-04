import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Tidy debtor card shared by the customers and suppliers debt tabs.
class DebtPartyCard extends StatelessWidget {
  final String name;
  final String? phone;
  final double totalInvoices;
  final double totalPaid;
  final double remainingDebt;
  final int invoiceCount;
  final int pendingCount;
  final int overdueCount;
  final String? latestDueDate;
  final VoidCallback onTap;
  final VoidCallback? onPaymentTap;

  const DebtPartyCard({
    super.key,
    required this.name,
    required this.phone,
    required this.totalInvoices,
    required this.totalPaid,
    required this.remainingDebt,
    required this.invoiceCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.latestDueDate,
    required this.onTap,
    this.onPaymentTap,
  });

  bool get _hasDebt => remainingDebt > 0;

  double get _paidRatio {
    if (totalInvoices <= 0) return 0;
    return (totalPaid / totalInvoices).clamp(0.0, 1.0);
  }

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
  }

  String? get _dueDateLabel {
    final raw = latestDueDate;
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;
    final dueDate = _dueDateLabel;

    return sc.Card(
      padding: const EdgeInsets.all(16),
      child: sc.Clickable(
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.muted,
                    borderRadius: theme.borderRadiusMd,
                  ),
                  child: Text(
                    _initial,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            sc.LucideIcons.phone,
                            size: 12,
                            color: scheme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone?.isNotEmpty == true ? phone! : 'بدون رقم',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(remainingDebt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _hasDebt
                            ? scheme.foreground
                            : scheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasDebt ? 'المتبقي' : 'مسدد',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'نسبة السداد',
                  style: TextStyle(fontSize: 11, color: scheme.mutedForeground),
                ),
                const Spacer(),
                Text(
                  '${(_paidRatio * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _paidRatio,
                minHeight: 6,
                backgroundColor: scheme.muted,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Meta(
                  icon: sc.LucideIcons.receiptText,
                  label: '$invoiceCount فاتورة',
                ),
                if (pendingCount > 0)
                  _Meta(
                    icon: sc.LucideIcons.clock,
                    label: '$pendingCount معلقة',
                  ),
                if (overdueCount > 0)
                  _Meta(
                    icon: sc.LucideIcons.triangleAlert,
                    label: '$overdueCount متأخرة',
                    color: scheme.destructive,
                  ),
                if (dueDate != null)
                  _Meta(icon: sc.LucideIcons.calendarClock, label: dueDate),
              ],
            ),
            if (_hasDebt && onPaymentTap != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: sc.Button(
                  alignment: Alignment.center,
                  style: const sc.ButtonStyle.secondary(),
                  onPressed: onPaymentTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sc.LucideIcons.banknote, size: 16),
                      SizedBox(width: 8),
                      Text('تسجيل دفعة'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Meta({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.mutedForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: effectiveColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: effectiveColor)),
      ],
    );
  }
}
