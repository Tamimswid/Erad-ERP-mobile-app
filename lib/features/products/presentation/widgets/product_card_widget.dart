import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../../../core/constants/app_constants.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final Function(ProductModel product) onEdit;
  final Function(String productId) onDelete;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductName(),
                const SizedBox(height: AppConstants.spacingMd),
                _buildPricingSection(),
                const SizedBox(height: AppConstants.spacingMd),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      product.nameWithMeasurementUnit,
      style: TextStyle(
        fontSize: AppFonts.fontSizeLarge,
        fontWeight: AppFonts.fontWeightSemiBold,
        color: AppColors.text,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPricingSection() {
    return Row(
      children: [
        Expanded(
          child: _buildPriceBox(
            label: 'شراء',
            price: product.purchasePrice,
          ),
        ),
        const SizedBox(width: AppConstants.spacing),
        Expanded(
          child: _buildPriceBox(
            label: 'بيع',
            price: product.salePrice,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBox({
    required String label,
    required double price,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              fontWeight: AppFonts.fontWeightMedium,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price > 0 ? price.toStringAsFixed(2) : '-',
            style: TextStyle(
              fontSize: AppFonts.fontSizeXLarge,
              fontWeight: AppFonts.fontWeightBold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onEdit(product),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('تعديل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSm),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacing),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onDelete(product.id),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}