import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';

class InvoiceActionButtonsWidget extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onEdit;
  final VoidCallback onUpdateInvoiceStatus;
  final VoidCallback onUpdatePaymentStatus;
  final VoidCallback onDelete;

  const InvoiceActionButtonsWidget({
    super.key,
    required this.onExportPdf,
    required this.onEdit,
    required this.onUpdateInvoiceStatus,
    required this.onUpdatePaymentStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // PDF Export Button
          _buildActionButton(
            icon: Icons.picture_as_pdf,
            label: 'تصدير PDF',
            onPressed: onExportPdf,
            isSecondary: true,
          ),
          
          const SizedBox(width: 12),
          
          // Edit Button
          _buildActionButton(
            icon: Icons.edit,
            label: 'تحرير',
            onPressed: onEdit,
            isPrimary: true,
          ),

          const SizedBox(width: 12),

          // Update Invoice Status Button
          _buildActionButton(
            icon: Icons.receipt,
            label: 'حالة الفاتورة',
            onPressed: onUpdateInvoiceStatus,
            isSecondary: true,
          ),

          const SizedBox(width: 12),

          // Update Payment Status Button
          _buildActionButton(
            icon: Icons.payment,
            label: 'حالة الدفع',
            onPressed: onUpdatePaymentStatus,
            isSecondary: true,
          ),
          
          const SizedBox(width: 12),
          
          // Delete Button
          _buildActionButton(
            icon: Icons.delete,
            label: 'حذف',
            onPressed: onDelete,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
    bool isDanger = false,
  }) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;
    
    if (isPrimary) {
      backgroundColor = AppColors.primary;
      foregroundColor = Colors.white;
      borderSide = BorderSide.none;
    } else if (isDanger) {
      backgroundColor = Colors.transparent;
      foregroundColor = AppColors.error;
      borderSide = BorderSide(color: AppColors.error.withOpacity(0.3));
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = AppColors.text;
      borderSide = BorderSide(color: AppColors.border);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.fromBorderSide(borderSide),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: foregroundColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeMedium,
                    fontWeight: AppFonts.fontWeightMedium,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
