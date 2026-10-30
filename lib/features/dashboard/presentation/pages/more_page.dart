import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المزيد'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: GridView(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          children: [
            _NavCard(
              icon: Iconsax.profile_2user,
              title: 'العملاء',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
            ),
            _NavCard(
              icon: Iconsax.shop,
              title: 'الموردون',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.pushNamed(context, AppRoutes.suppliers),
            ),
            _NavCard(
              icon: Iconsax.money_send,
              title: 'النفقات',
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.pushNamed(context, AppRoutes.expenses),
            ),
            _NavCard(
              icon: Iconsax.money_recive,
              title: 'السحوبات',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.pushNamed(context, AppRoutes.withdrawals),
            ),
            _NavCard(
              icon: Iconsax.box,
              title: 'المنتجات',
              color: const Color(0xFFDE24C8),
              onTap: () => Navigator.pushNamed(context, AppRoutes.products),
            ),
            _NavCard(
              icon: Iconsax.chart_2,
              title: 'التقارير',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.pushNamed(context, AppRoutes.takrirler),
            ),
            _NavCard(
              icon: Iconsax.setting_2,
              title: 'الإعدادات',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
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
              Spacer(),
              Icon(icon, color: AppColors.primary, size: 40),
              Spacer(),
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
