import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/core/widgets/app_stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class DebtsSummaryCard extends StatelessWidget {
  final String title;
  final double totalDebt;
  final double totalInvoices;
  final double totalPaid;
  final int? partyCount;
  final IconData countIcon;

  const DebtsSummaryCard({
    super.key,
    required this.title,
    required this.totalDebt,
    required this.totalInvoices,
    required this.totalPaid,
    this.partyCount,
    this.countIcon = sc.LucideIcons.users,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return sc.Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
                ),
              ),
              if (partyCount != null)
                _CountChip(count: partyCount!, icon: countIcon),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  NumberFormatter.format(totalDebt),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: scheme.foreground,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  NumberFormatter.getCurrencySymbol(),
                  style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sc.Divider(color: scheme.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  label: 'إجمالي الفواتير',
                  value: NumberFormatter.formatShort(totalInvoices),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppStatTile(
                  label: 'المدفوع',
                  value: NumberFormatter.formatShort(totalPaid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final IconData icon;

  const _CountChip({required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.muted,
        borderRadius: theme.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.mutedForeground),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
