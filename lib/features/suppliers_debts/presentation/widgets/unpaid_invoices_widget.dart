import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/suppliers_debts/data/models/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

export 'package:erad/features/suppliers_debts/data/models/invoice_model.dart';

class UnpaidInvoiceRow extends StatelessWidget {
  final PurchaseInvoiceModel invoice;

  const UnpaidInvoiceRow({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(scheme);

    return sc.Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          invoice.invoiceNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: theme.borderRadiusXs,
                        ),
                        child: Text(
                          _statusText(invoice.paymentStatus),
                          style: TextStyle(fontSize: 10, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        sc.LucideIcons.calendar,
                        size: 11,
                        color: scheme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        invoice.invoiceDate.toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.mutedForeground,
                        ),
                      ),
                    ],
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
                  '${NumberFormatter.format(invoice.remainingAmount)} ${NumberFormatter.getCurrencySymbol()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'من ${NumberFormatter.formatShort(invoice.totalAmount)}',
                  style: TextStyle(fontSize: 11, color: scheme.mutedForeground),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(sc.ColorScheme scheme) {
    switch (invoice.paymentStatus) {
      case 'debt':
        return scheme.destructive;
      case 'partial':
        return scheme.chart2;
      case 'paid':
        return scheme.primary;
      default:
        return scheme.mutedForeground;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'debt':
        return 'مستحق';
      case 'partial':
        return 'مدفوع جزئي';
      case 'paid':
        return 'مدفوع';
      default:
        return status;
    }
  }
}
