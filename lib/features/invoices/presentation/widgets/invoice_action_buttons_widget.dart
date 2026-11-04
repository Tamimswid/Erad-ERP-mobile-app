import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

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
                  icon: sc.LucideIcons.banknote,
                  label: 'الدفع',
                  onPressed: onUpdatePaymentStatus,
                  style: sc.ButtonStyle.primary(),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _buildActionButton(
                  icon: sc.LucideIcons.fileText,
                  label: 'PDF',
                  onPressed: onExportPdf,
                  style: sc.ButtonStyle.outline(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: sc.LucideIcons.pencil,
                  label: 'تعديل',
                  onPressed: onEdit,
                  style: sc.ButtonStyle.outline(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: sc.LucideIcons.trash2,
                  label: 'حذف الفاتورة',
                  onPressed: onDelete,
                  style: sc.ButtonStyle.destructive(),
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
    required sc.ButtonStyle style,
  }) {
    return sc.Button(
      alignment: Alignment.center,
      style: style,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              fontWeight: AppFonts.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}
