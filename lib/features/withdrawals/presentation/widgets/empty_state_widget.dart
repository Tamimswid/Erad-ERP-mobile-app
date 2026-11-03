import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:erad/core/constants/app_constants.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            sc.LucideIcons.wallet,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text('لا يوجد سحوبات'),
          SizedBox(height: 8),
          Text('أضف سحب جديد للبدء'),
        ],
      ),
    );
  }
}
