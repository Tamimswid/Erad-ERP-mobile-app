import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/services/user_service.dart';
import '../../../cities/data/models/city.dart';
import '../../../cities/presentation/widgets/city_picker_field.dart';
import '../../data/models/supplier.dart';
import '../bloc/supplier_cubit.dart';

class SupplierFormWidget extends StatefulWidget {
  final SupplierModel? supplier;
  final Function(SupplierModel) onSubmit;
  final SupplierCubit? cubit;

  const SupplierFormWidget({
    super.key,
    this.supplier,
    required this.onSubmit,
    this.cubit,
  });

  @override
  State<SupplierFormWidget> createState() => _SupplierFormWidgetState();
}

class _SupplierFormWidgetState extends State<SupplierFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CityModel? _selectedCity;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    if (supplier != null) {
      _nameController.text = supplier.name;
      _selectedCity = _initialCity(supplier);
    }
  }

  /// يستخدم المدينة المرتبطة بـ `city_id`، أو النص القديم للتوافق مع
  /// السجلات التي أُنشئت قبل جدول المدن.
  CityModel? _initialCity(SupplierModel supplier) {
    final legacyCity = supplier.city?.trim();
    if (supplier.cityId == null && (legacyCity == null || legacyCity.isEmpty)) {
      return null;
    }
    return CityModel(
      id: supplier.cityId ?? '',
      name: supplier.cityName ?? legacyCity ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.supplier;
    final selectedCityId = _selectedCity?.id;
    final cityId = selectedCityId == null || selectedCityId.isEmpty
        ? null
        : selectedCityId;
    final supplier = SupplierModel(
      id: existing?.id ?? '',
      userId: existing?.userId ?? await UserService.getUserId() ?? '',
      name: _nameController.text.trim(),
      phone: existing?.phone,
      city: existing?.city,
      cityId: cityId,
      cityName: _selectedCity?.name,
      currentBalance: existing?.currentBalance ?? 0.0,
      totalPurchases: existing?.totalPurchases ?? 0.0,
      isActive: existing?.isActive ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.cubit != null) {
      widget.cubit!.createSupplier(supplier);
      if (mounted) Navigator.pop(context);
    } else {
      widget.onSubmit(supplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم المورد *',
              prefixIcon: Icon(sc.LucideIcons.building2),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم المورد مطلوب';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CityPickerField(
            value: _selectedCity,
            onChanged: (city) => setState(() => _selectedCity = city),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: sc.Button(
              alignment: Alignment.center,
              style: sc.ButtonStyle.primary(),
              onPressed: _submit,
              child: Text(widget.supplier == null ? 'إضافة' : 'تحديث'),
            ),
          ),
        ],
      ),
    );
  }
}
