import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../data/models/city.dart';
import '../../data/repositories/city_repository.dart';

/// نتيجة اختيار المدينة.
///
/// `null` يعني أن المستخدم أغلق الورقة دون تغيير، بينما
/// [CitySelectionResult] مع `city == null` تعني مسح الاختيار.
class CitySelectionResult {
  final CityModel? city;

  const CitySelectionResult(this.city);
}

class CityPickerSheet extends StatefulWidget {
  final CityRepository repository;
  final CityModel? selected;
  final bool allowClear;

  const CityPickerSheet({
    super.key,
    required this.repository,
    this.selected,
    this.allowClear = true,
  });

  static Future<CitySelectionResult?> show(
    BuildContext context, {
    CityModel? selected,
    bool allowClear = true,
    CityRepository? repository,
  }) {
    return showModalBottomSheet<CitySelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CityPickerSheet(
        repository: repository ?? sl.sl<CityRepository>(),
        selected: selected,
        allowClear: allowClear,
      ),
    );
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  List<CityModel> _cities = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.repository.getCities();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (cities) => setState(() {
        _isLoading = false;
        _cities = cities;
      }),
    );
  }

  void _select(CityModel? city) {
    Navigator.pop(context, CitySelectionResult(city));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'اختر المدينة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(sc.LucideIcons.x, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            sc.Button(
              alignment: Alignment.center,
              style: sc.ButtonStyle.outline(),
              onPressed: _loadCities,
              child: const Text('حاول ثانية'),
            ),
          ],
        ),
      );
    }

    if (_cities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sc.LucideIcons.mapPin,
              size: 40,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد مدن مضافة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'أضف المدن إلى جدول cities ثم أعد المحاولة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final showClearOption = widget.allowClear && widget.selected != null;

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _cities.length + (showClearOption ? 1 : 0),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        if (showClearOption && index == 0) {
          return _buildTile(
            label: 'بدون مدينة',
            isSelected: false,
            onTap: () => _select(null),
          );
        }

        final city = _cities[showClearOption ? index - 1 : index];
        final isSelected = widget.selected?.id == city.id;
        return _buildTile(
          label: city.name,
          isSelected: isSelected,
          onTap: () => _select(city),
        );
      },
    );
  }

  Widget _buildTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: isSelected ? AppColors.text : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(sc.LucideIcons.check, size: 18, color: AppColors.text)
          : null,
    );
  }
}
