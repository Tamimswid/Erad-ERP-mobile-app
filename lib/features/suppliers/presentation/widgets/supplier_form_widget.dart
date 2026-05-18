import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_service.dart';
import '../../data/models/supplier.dart';
import '../bloc/supplier_cubit.dart';

class SupplierFormWidget extends StatefulWidget {
  final SupplierModel? supplier;
  final Function(SupplierModel) onSubmit;
  final SupplierCubit? cubit;

  const SupplierFormWidget({super.key, this.supplier, required this.onSubmit, this.cubit});

  @override
  State<SupplierFormWidget> createState() => _SupplierFormWidgetState();
}

class _SupplierFormWidgetState extends State<SupplierFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _phoneController.text = widget.supplier!.phone ?? '';
      _cityController.text = widget.supplier!.city ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final String? userId = await UserService.getUserId();
      final supplier = SupplierModel(
        id: widget.supplier?.id ?? '',
        userId: userId!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        currentBalance: widget.supplier?.currentBalance ?? 0.0,
        totalPurchases: widget.supplier?.totalPurchases ?? 0.0,
        isActive: widget.supplier?.isActive ?? true,
        createdAt: widget.supplier?.createdAt ?? now,
        updatedAt: now,
      );
      
      if (widget.cubit != null) {
        widget.cubit!.createSupplier(supplier);
      } else {
        widget.onSubmit(supplier);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المورد *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم المورد مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'المدينة',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submit();
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.supplier == null ? 'إضافة' : 'تحديث'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
