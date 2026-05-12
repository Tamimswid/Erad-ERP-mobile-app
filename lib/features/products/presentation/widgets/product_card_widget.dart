import 'package:flutter/material.dart';
import '../../data/models/product.dart';

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

  // Blue Color System
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  
  // Gray Color System
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(),
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildPricingSection(),
                const SizedBox(height: 16),
                _buildStockSection(),
                const SizedBox(height: 16),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name and status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.nameWithMeasurementUnit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: gray900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 8),
        // Category and unit tags
        Row(
          children: [
            _buildCategoryTag(),
            const SizedBox(width: 8),
            _buildUnitTag(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = product.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? blue50 : gray100,
        border: Border.all(
          color: isActive ? blue200 : gray200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isActive ? blue700 : gray600,
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: blue50,
        border: Border.all(color: blue200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category,
            size: 12,
            color: blue700,
          ),
          const SizedBox(width: 4),
          Text(
            product.categoryName ?? 'بدون فئة',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: blue700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: gray50,
        border: Border.all(color: gray200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${product.measurement} ${product.unit} ',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: gray600,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: gray200,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات السعر',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: gray500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPriceBox('شراء', product.purchasePrice, true)),
            const SizedBox(width: 8),
            Expanded(child: _buildPriceBox('بيع', product.salePrice, true)),
            const SizedBox(width: 8),
            Expanded(child: _buildPriceBox('أدنى', product.minSalePrice, product.minSalePrice > 0)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBox(String label, double price, bool hasValue) {
    final isActive = hasValue && price > 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? blue50 : gray50,
        border: Border.all(
          color: isActive ? blue100 : gray200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? blue600 : gray500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasValue ? price.toStringAsFixed(2) : '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? gray900 : gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات المخزون',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: gray500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        _buildStockInfoRow('الحالي', product.currentStock.toString()),
        const SizedBox(height: 4),
        _buildStockInfoRow('الحد الأدنى', product.minStock.toString()),
        if (product.maxStock != null) ...[
          const SizedBox(height: 4),
          _buildStockInfoRow('الحد الأقصى', product.maxStock!.toString()),
        ],
        const SizedBox(height: 12),
        _buildStockProgressBar(),
        const SizedBox(height: 8),
        _buildStockStatusBadge(),
      ],
    );
  }

  Widget _buildStockInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: gray500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildStockProgressBar() {
    final maxStock = product.maxStock ?? (product.minStock * 2);
    final stockRatio = maxStock > 0 ? (product.currentStock / maxStock).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor;
    if (product.currentStock <= 0) {
      progressColor = Colors.red;
    } else if (stockRatio < 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = blue500;
    }
    
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: gray200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          // Always show full width background
          Container(
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Show actual stock level as colored bar
          if (product.currentStock > 0)
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: stockRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          // Show very small line when empty
          if (product.currentStock <= 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockStatusBadge() {
    final status = _getStockStatusText();
    final icon = _getStockStatusIcon();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: blue50,
        border: Border.all(color: blue200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: blue700,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: blue700,
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
            onPressed:() => onEdit(product) ,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('تعديل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:() => onDelete(product.id),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: gray700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStockStatusText() {
    final currentStock = product.currentStock;
    final minStock = product.minStock;
    
    if (currentStock <= 0) {
      return 'المخزون فارغ';
    } else if (currentStock <= minStock) {
      return 'المخزون منخفض';
    } else {
      return 'المخزون كافٍ';
    }
  }

  IconData _getStockStatusIcon() {
    final currentStock = product.currentStock;
    final minStock = product.minStock;
    
    if (currentStock <= 0) {
      return Icons.cancel_outlined;
    } else if (currentStock <= minStock) {
      return Icons.error_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }
}
