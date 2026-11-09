import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/cities/data/models/city.dart';
import 'package:erad/features/cities/presentation/widgets/city_picker_field.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/customer_cubit.dart';

class CustomerFormWidget extends StatefulWidget {
  final CustomerModel? customerModel;
  final Function(CustomerModel customerModel) onTap;
  final CustomerCubit? cubit;

  const CustomerFormWidget({
    super.key,
    this.customerModel,
    required this.onTap,
    this.cubit,
  });

  @override
  State<CustomerFormWidget> createState() => _CustomerFormWidgetState();
}

class _CustomerFormWidgetState extends State<CustomerFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CityModel? _selectedCity;

  @override
  void initState() {
    super.initState();
    final customer = widget.customerModel;
    if (customer != null) {
      _nameController.text = customer.name;
      _selectedCity = _initialCity(customer);
    }
  }

  /// يستخدم المدينة المرتبطة بـ `city_id`، أو النص القديم للتوافق مع
  /// السجلات التي أُنشئت قبل جدول المدن.
  CityModel? _initialCity(CustomerModel customer) {
    final legacyCity = customer.city?.trim();
    if (customer.cityId == null && (legacyCity == null || legacyCity.isEmpty)) {
      return null;
    }
    return CityModel(
      id: customer.cityId ?? '',
      name: customer.cityName ?? legacyCity ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.customerModel;
    final selectedCityId = _selectedCity?.id;
    final cityId = selectedCityId == null || selectedCityId.isEmpty
        ? null
        : selectedCityId;
    final customer = CustomerModel(
      id: existing?.id ?? '',
      userId: existing?.userId ?? await UserService.getUserId() ?? '',
      code: existing?.code ?? '',
      name: _nameController.text.trim(),
      phone: existing?.phone,
      address: existing?.address,
      city: existing?.city,
      cityId: cityId,
      cityName: _selectedCity?.name,
      creditLimit: existing?.creditLimit ?? 0,
      currentBalance: existing?.currentBalance ?? 0,
      totalPurchases: existing?.totalPurchases ?? 0,
      isActive: existing?.isActive ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
    );

    if (widget.cubit != null) {
      widget.cubit!.createCustomer(customer);
      if (mounted) Navigator.pop(context);
    } else {
      widget.onTap(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم العميل *',
              prefixIcon: Icon(sc.LucideIcons.user),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم العميل مطلوب';
              }
              return null;
            },
          ),
          CityPickerField(
            value: _selectedCity,
            onChanged: (city) => setState(() => _selectedCity = city),
          ),
          SizedBox(
            width: double.infinity,
            child: sc.Button(
              alignment: Alignment.center,
              style: sc.ButtonStyle.primary(),
              onPressed: _submitForm,
              child: Text(widget.customerModel == null ? 'إضافة' : 'تحديث'),
            ),
          ),
        ],
      ),
    );
  }
}
