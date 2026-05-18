import 'package:erad/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/withdrawal.dart';
import '../../data/models/partner.dart';
import 'withdrawal_detail_dialog.dart';

class WithdrawalsTableWidget extends StatelessWidget {
  final List<Withdrawal> withdrawals;
  final List<Partner> partners;
  final Function(Withdrawal) onDelete;
  final Function(Withdrawal) onTap;

  const WithdrawalsTableWidget({
    super.key,
    required this.withdrawals,
    required this.partners,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: withdrawals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final withdrawal = withdrawals[index];
        final partner = partners.where((p) => p.id == withdrawal.partnerId).firstOrNull;
        return _buildCard(context, withdrawal: withdrawal, partner: partner);
      },
    );
  }

  Widget _buildCard(BuildContext context, {
    required Withdrawal withdrawal,
    required Partner? partner,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context, withdrawal, partner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner?.name ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(withdrawal.withdrawalDate),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (withdrawal.description?.isNotEmpty ?? false) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.notes,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              withdrawal.description!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppUtils.formatNumber(withdrawal.amount)} ${NumberFormatter.getCurrencySymbol()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showDeleteConfirmation(context, withdrawal),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Withdrawal withdrawal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا السحب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete(withdrawal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Text(
          'لا توجد سحوبات',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Withdrawal withdrawal, Partner? partner) {
    WithdrawalDetailDialog.show(context, withdrawal, partner);
  }
}