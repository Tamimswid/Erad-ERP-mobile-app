import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.payments,
                  label: 'الدفع',
                  onPressed: onUpdatePaymentStatus,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  onPressed: onExportPdf,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit,
                  label: 'تعديل',
                  onPressed: onEdit,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'حذف الفاتورة',
                  onPressed: onDelete,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: color,
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
