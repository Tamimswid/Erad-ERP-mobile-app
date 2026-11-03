import 'package:erad/core/services/user_service.dart';
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
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _creditLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customerModel != null) {
      _codeController.text = widget.customerModel!.code;
      _nameController.text = widget.customerModel!.name;
      _phoneController.text = widget.customerModel!.phone ?? '';
      _addressController.text = widget.customerModel!.address ?? '';
      _cityController.text = widget.customerModel!.city ?? '';
      _creditLimitController.text = widget.customerModel!.creditLimit
          .toString();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final customer = CustomerModel(
        id: widget.customerModel?.id ?? '',
        userId:
            widget.customerModel?.userId ?? await UserService.getUserId() ?? '',
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
        currentBalance: widget.customerModel?.currentBalance ?? 0,
        totalPurchases: widget.customerModel?.totalPurchases ?? 0,
        isActive: widget.customerModel?.isActive ?? true,
        createdAt: widget.customerModel?.createdAt ?? now,
        updatedAt: now,
        deletedAt: widget.customerModel?.deletedAt,
      );
      if (widget.cubit != null) {
        widget.cubit!.createCustomer(customer);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        widget.onTap(customer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(sc.LucideIcons.phone),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'المدينة',
                      prefixIcon: Icon(sc.LucideIcons.building2),
                    ),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(sc.LucideIcons.mapPin),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: _submitForm,
                    child: Text(
                      widget.customerModel == null ? 'إضافة' : 'تحديث',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: sc.Button(
                    style: sc.ButtonStyle.outline(),
                    onPressed: () {
                      _formKey.currentState?.reset();
                    },
                    child: const Text('مسح'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
