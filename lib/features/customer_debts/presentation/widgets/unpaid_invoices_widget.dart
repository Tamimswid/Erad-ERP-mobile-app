import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/data/models/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

export 'package:erad/features/customer_debts/data/models/invoice_model.dart';

/// صف فاتورة دين واحدة
class UnpaidInvoiceRow extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const UnpaidInvoiceRow({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  String get _shortNumber {
    final number = invoice.invoiceNumber;
    return number.length > 3 ? number.substring(number.length - 3) : number;
  }

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return sc.Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: sc.Clickable(
        onPressed: onTap,
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
                  _shortNumber,
                  style: TextStyle(
                    fontSize: 12,
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
                    Text(
                      invoice.invoiceNumber,
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
                      invoice.invoiceDate,
                      style: TextStyle(
                        fontSize: 12,
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
                    '${AppUtils.formatNumber(invoice.remainingAmount)} ${NumberFormatter.getCurrencySymbol()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.moneyOut,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'من ${NumberFormatter.formatShort(invoice.totalAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.mutedForeground,
                    ),
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
      ),
    );
  }
}
