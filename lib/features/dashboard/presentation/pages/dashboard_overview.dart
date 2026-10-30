import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:erad/features/dashboard/presentation/widgets/app_bar_date_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../bloc/dashboard_cubit.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<DashboardCubit>(),
      child: const _DashboardOverviewContent(),
    );
  }
}

class _DashboardOverviewContent extends StatelessWidget {
  const _DashboardOverviewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppBarDateFilter(color: AppColors.surface),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (state is! DashboardLoaded) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kasa Bakiyesi - En önemli bilgi
                _CashBalanceCard(amount: state.cashInHand),
                
                const SizedBox(height: AppConstants.spacingMd),
                
                // 2. Satış ve Alım Özeti
                _SummaryRow(
                  salesAmount: state.totalSalesRevenue,
                  purchaseAmount: state.totalPurchaseCost,
                ),
                
                const SizedBox(height: AppConstants.spacingMd),
                
                // 3. Ürün Stok Listesi
                if (state.productStock.isNotEmpty)
                  _ProductStockList(products: state.productStock),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Kasa bakiyesi kartı - Büyük ve okunabilir
class _CashBalanceCard extends StatelessWidget {
  final double amount;
  
  const _CashBalanceCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرصيد الحالي',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormatter.format(amount),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          Text(
            NumberFormatter.getCurrencySymbol(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satış ve Alım özeti - Yan yana
class _SummaryRow extends StatelessWidget {
  final double salesAmount;
  final double purchaseAmount;
  
  const _SummaryRow({
    required this.salesAmount,
    required this.purchaseAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'إجمالي المبيعات',
            amount: salesAmount,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: _SummaryCard(
            title: 'إجمالي المشتريات',
            amount: purchaseAmount,
          ),
        ),
      ],
    );
  }
}

/// Tek özet kartı
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  
  const _SummaryCard({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormatter.formatShort(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ürün stok listesi - Temiz tablo
class _ProductStockList extends StatelessWidget {
  final List products;
  
  const _ProductStockList({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Text(
              'المخزون',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          
          // Tablo başlığı
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'المنتج',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'مُباع',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الباقي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Ürün listesi
          ...products.map((product) => _ProductRow(product: product)),
        ],
      ),
    );
  }
}

/// Tek ürün satırı
class _ProductRow extends StatelessWidget {
  final dynamic product;
  
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final remaining = product.calculatedRemainingStock;
    final sold = product.totalPurchasedQty;
    final isLow = remaining <= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Ürün adı
          Expanded(
            flex: 3,
            child: Text(
              product.productName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Satılan miktar
          Expanded(
            flex: 1,
            child: Text(
              '$sold',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Kalan miktar
          Expanded(
            flex: 1,
            child: Text(
              '$remaining',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLow ? AppColors.error : AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
