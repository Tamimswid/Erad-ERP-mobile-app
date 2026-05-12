import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:flutter/material.dart';

class CustomerFormWidget extends StatefulWidget {
  final CustomerModel? customerModel;
  final Function(CustomerModel customerModel) onTap;
  const CustomerFormWidget({super.key, this.customerModel, required this.onTap});

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
      _creditLimitController.text = widget.customerModel!.creditLimit.toString();
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
        userId: widget.customerModel?.userId ?? await UserService.getUserId() ?? '',
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
        currentBalance: widget.customerModel?.currentBalance ?? 0,
        totalPurchases: widget.customerModel?.totalPurchases ?? 0,
        isActive: widget.customerModel?.isActive ?? true,
        createdAt: widget.customerModel?.createdAt ?? now,
        updatedAt: now,
        deletedAt: widget.customerModel?.deletedAt,
      );
      widget.onTap(customer);
      if (context.mounted) {
        Navigator.pop(context);
      }
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
              prefixIcon: Icon(Icons.person),
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
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    prefixIcon: Icon(Icons.location_city),
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
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(widget.customerModel == null ? 'إضافة' : 'تحديث'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
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
    );
  }
}
