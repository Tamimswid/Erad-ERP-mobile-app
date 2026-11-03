import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/reports/presentation/pages/customer_invoices_page.dart';
import 'package:erad/features/reports/presentation/pages/stock_tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class TakrirlerPage extends StatelessWidget {
  const TakrirlerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      headers: [
        sc.AppBar(title: const Text('التقارير')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: GridView(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          children: [
            _ReportCard(
              icon: sc.LucideIcons.receiptText,
              title: 'فواتير مشتري',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerInvoicesPage(isSupplier: false),
                ),
              ),
            ),
            _ReportCard(
              icon: sc.LucideIcons.receiptText,
              title: 'فواتير مورد',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerInvoicesPage(isSupplier: true),
                ),
              ),
            ),
            _ReportCard(
              icon: sc.LucideIcons.packageSearch,
              title: 'تتبع المخزون',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockTrackingPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: sc.Clickable(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.text, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
