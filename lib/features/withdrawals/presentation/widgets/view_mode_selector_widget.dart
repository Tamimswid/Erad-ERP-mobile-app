import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

enum ViewMode { table, cards }

class ViewModeSelectorWidget extends StatelessWidget {
  final ViewMode currentMode;
  final ValueChanged<ViewMode> onModeChanged;

  const ViewModeSelectorWidget({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildModeButton(
          label: 'جدول',
          isActive: currentMode == ViewMode.table,
          onTap: () => onModeChanged(ViewMode.table),
        ),
        const SizedBox(width: 8),
        _buildModeButton(
          label: 'حسب المستخدم',
          isActive: currentMode == ViewMode.cards,
          onTap: () => onModeChanged(ViewMode.cards),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
