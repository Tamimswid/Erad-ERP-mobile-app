import 'package:flutter/material.dart';
import '../../data/models/withdrawal.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
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
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
