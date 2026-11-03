import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: sc.Card(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        clipBehavior: Clip.antiAlias,
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
          child: sc.Button(
            style: sc.ButtonStyle.secondary(),
            onPressed: () => onEdit(product),
            leading: const Icon(sc.LucideIcons.pencil, size: 16),
            child: const Text('تعديل'),
          ),
        ),
        const SizedBox(width: AppConstants.spacing),
        Expanded(
          child: sc.Button(
            style: sc.ButtonStyle.destructive(),
            onPressed: () => onDelete(product.id),
            leading: const Icon(sc.LucideIcons.trash2, size: 16),
            child: const Text('حذف'),
          ),
        ),
      ],
    );
  }
}