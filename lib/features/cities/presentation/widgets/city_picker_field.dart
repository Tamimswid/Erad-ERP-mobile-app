import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/constants/app_constants.dart';
import '../../data/models/city.dart';
import '../../data/repositories/city_repository.dart';
import 'city_picker_sheet.dart';

/// حقل اختيار مدينة واحدة من جدول `cities`.
class CityPickerField extends StatelessWidget {
  final CityModel? value;
  final ValueChanged<CityModel?> onChanged;
  final String label;
  final String hint;
  final CityRepository? repository;

  const CityPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'المدينة',
    this.hint = 'اختر المدينة',
    this.repository,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await CityPickerSheet.show(
      context,
      selected: value,
      repository: repository,
    );
    if (result == null) return;
    onChanged(result.city);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(sc.LucideIcons.mapPin, size: 20),
          suffixIcon: value == null
              ? const Icon(sc.LucideIcons.chevronDown, size: 18)
              : IconButton(
                  onPressed: () => onChanged(null),
                  icon: const Icon(sc.LucideIcons.x, size: 16),
                  color: AppColors.textSecondary,
                  tooltip: 'مسح المدينة',
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          value?.name ?? hint,
          style: TextStyle(
            fontSize: 14,
            color: value == null ? AppColors.textSecondary : AppColors.text,
          ),
        ),
      ),
    );
  }
}
