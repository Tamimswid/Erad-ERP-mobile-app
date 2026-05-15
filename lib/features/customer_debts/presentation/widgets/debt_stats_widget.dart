import 'dart:async';

import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/customer_debts/presentation/bloc/customer_debt_cubit.dart';
import 'package:erad/features/customer_debts/presentation/widgets/debt_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class DebtStatsWidget extends StatefulWidget {
  final double totalDebt;
  final double totalInvoices;
  final double totalPaid;
  final int debtorCount;

  const DebtStatsWidget({
    super.key,
    required this.totalDebt,
    required this.totalInvoices,
    required this.totalPaid,
    required this.debtorCount,
  });

  @override
  State<DebtStatsWidget> createState() => _DebtStatsWidgetState();
}

class _DebtStatsWidgetState extends State<DebtStatsWidget> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Debt Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي الديون',
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeSmall,
                        fontWeight: AppFonts.fontWeightMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormatter.formatCurrency(widget.totalDebt),
                      style: TextStyle(
                        fontSize: AppFonts.fontSizeXLarge,
                        fontWeight: AppFonts.fontWeightBold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMd,
                    ),
                  ),
                  padding: EdgeInsets.all(5),
                  // width: 50,
                  // height: 30,
                  child: Row(
                    spacing: 5,
                    children: [
                      Icon(Iconsax.user, size: 15),
                      Text(widget.debtorCount.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sub Stats Grid
          Row(
            spacing: 10,
            children: [
              _buildMobileStatItem(
                context,
                'مجموع الفواتير',
                NumberFormatter.formatCurrency(widget.totalInvoices),
                Icons.receipt_long_outlined,
              ),
              _buildMobileStatItem(
                context,
                'المبلغ المدفوع',
                NumberFormatter.formatCurrency(widget.totalPaid),
                Icons.payment_outlined,
              ),
            ],
          ),

          SizedBox(height: 16),
          DebtSearchWidget(
                      onSearchChanged: (query) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(
                          const Duration(milliseconds: 500),
                          () {
                            context
                                .read<CustomerDebtCubit>()
                                .searchCustomerDebts(query);
                          },
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildMobileStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
