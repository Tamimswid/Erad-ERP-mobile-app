import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../bloc/dashboard_cubit.dart';

class ProductSalesSection extends StatefulWidget {
  const ProductSalesSection({super.key});

  @override
  State<ProductSalesSection> createState() => _ProductSalesSectionState();
}

class _ProductSalesSectionState extends State<ProductSalesSection> {
  String? selectedProductName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        // Use purchase data (from purchase invoices) instead of sales data
        final productsByPurchases = state.topProductsByPurchases ?? const [];

        if (productsByPurchases.isEmpty) {
          return _buildEmptyState();
        }

        // Set default selection if not set
        if (selectedProductName == null || 
            !productsByPurchases.any((p) => p['name'] == selectedProductName)) {
          selectedProductName = productsByPurchases.first['name'] as String;
        }

        // Find selected product data
        final selectedProduct = productsByPurchases.firstWhere(
          (p) => p['name'] == selectedProductName,
          orElse: () => productsByPurchases.first,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المشتريات حسب المنتج',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Working Product Dropdown
              _buildProductDropdown(productsByPurchases),
              const SizedBox(height: 24),
              // Quantity Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppUtils.formatNumber((selectedProduct['quantity'] as num).toDouble(), decimalDigits: 0),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text(
                  //   selectedProduct['unit'] as String,
                  //   style: const TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //     color: AppColors.textSecondary,
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'إجمالي المشتريات: ${selectedProduct['name']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductDropdown(List<Map<String, dynamic>> products) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedProductName,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: products.map((product) {
            return DropdownMenuItem<String>(
              value: product['name'] as String,
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedProductName = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المشتريات حسب المنتج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'لا توجد بيانات مشتريات',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
