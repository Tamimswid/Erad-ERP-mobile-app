import 'package:erad/core/widgets/app_quick_action.dart';
import 'package:erad/core/widgets/app_section_header.dart';
import 'package:erad/features/expenses/presentation/pages/expenses_page.dart';
import 'package:erad/features/invoices/presentation/pages/create_invoice_page.dart';
import 'package:erad/features/stock/presentation/pages/stock_review_page.dart';
import 'package:erad/features/withdrawals/presentation/pages/withdrawals_page.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'وصول سريع'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppQuickAction(
                icon: sc.LucideIcons.filePlus,
                label: 'إضافة فاتورة',
                onTap: () => _push(context, const CreateInvoicePage()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppQuickAction(
                icon: sc.LucideIcons.packageSearch,
                label: 'مراجعة المخزون',
                onTap: () => _push(context, const StockReviewPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppQuickAction(
                icon: sc.LucideIcons.receiptText,
                label: 'إضافة مصروف',
                onTap: () =>
                    _push(context, const ExpensesPage(autoOpenAdd: true)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppQuickAction(
                icon: sc.LucideIcons.banknote,
                label: 'إضافة سحب',
                onTap: () =>
                    _push(context, const WithdrawalsPage(autoOpenAdd: true)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
