import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:erad/core/constants/app_constants.dart';

class InvoiceEmptyStateWidget extends StatelessWidget {
  const InvoiceEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: sc.Card(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                sc.LucideIcons.search,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على فواتير',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب فلترة مختلفة أو حاول البحث مرة أخرى.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
