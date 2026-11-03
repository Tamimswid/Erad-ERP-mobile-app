import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return sc.Scaffold(
      headers: [sc.AppBar(title: const Text('المزيد'))],
      child: GridView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        children: [
          _NavCard(
            icon: sc.LucideIcons.users,
            title: 'العملاء',
            onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
          ),
          _NavCard(
            icon: sc.LucideIcons.store,
            title: 'الموردون',
            onTap: () => Navigator.pushNamed(context, AppRoutes.suppliers),
          ),
          _NavCard(
            icon: sc.LucideIcons.receiptText,
            title: 'النفقات',
            onTap: () => Navigator.pushNamed(context, AppRoutes.expenses),
          ),
          _NavCard(
            icon: sc.LucideIcons.banknote,
            title: 'السحوبات',
            onTap: () => Navigator.pushNamed(context, AppRoutes.withdrawals),
          ),
          _NavCard(
            icon: sc.LucideIcons.package,
            title: 'المنتجات',
            onTap: () => Navigator.pushNamed(context, AppRoutes.products),
          ),
          _NavCard(
            icon: sc.LucideIcons.chartColumn,
            title: 'التقارير',
            onTap: () => Navigator.pushNamed(context, AppRoutes.takrirler),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
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
