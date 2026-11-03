import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../data/models/withdrawal.dart';
import 'package:erad/core/constants/app_constants.dart';

class WithdrawalCard extends StatelessWidget {
  final Withdrawal withdrawal;
  final VoidCallback? onTap;

  const WithdrawalCard({
    super.key,
    required this.withdrawal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: sc.Card(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.muted,
              child: Icon(sc.LucideIcons.wallet, color: AppColors.textSecondary),
            ),
            title: Text(withdrawal.description ?? 'سحب'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التاريخ: ${withdrawal.withdrawalDate.toString().split(' ')[0]}'),
                Text('طريقة الدفع: ${withdrawal.paymentMethod}'),
              ],
            ),
            trailing: Text(
              '${withdrawal.amount.toStringAsFixed(2)} ل.س',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
