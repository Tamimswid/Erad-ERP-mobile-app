import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/takrirler/presentation/pages/customer_invoices_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TakrirlerPage extends StatelessWidget {
  const TakrirlerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: GridView(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          children: [
            _ReportCard(
              icon: Iconsax.receipt_text,
              title: 'فواتير مشتري',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerInvoicesPage(isSupplier: false),
                ),
              ),
            ),
            _ReportCard(
              icon: Iconsax.receipt_disscount,
              title: 'فواتير مورد',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerInvoicesPage(isSupplier: true),
                ),
              ),
            ),
            _ReportCard(
              icon: Iconsax.money_recive,
              title: 'ديون مشتري',
              color: const Color(0xFFEF4444),
              onTap: () {},
            ),
            _ReportCard(
              icon: Iconsax.money_send,
              title: 'ديون مورد',
              color: const Color(0xFFF59E0B),
              onTap: () {},
            ),
            _ReportCard(
              icon: Iconsax.box_search,
              title: 'تتبع المخزون',
              color: const Color(0xFFDE24C8),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.divider,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
            color: AppColors.surface,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(icon, color: AppColors.primary, size: 40),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
