import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/data/models/product_unit_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductFormWidget extends StatefulWidget {
  final ProductModel? product;
  final Function(ProductModel product) onSubmit;
  final List<ProductCategory> categoryList;

  const ProductFormWidget({
    super.key,
    this.product,
    required this.onSubmit,
    required this.categoryList,
  });

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

// unit
class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _measurementController = TextEditingController();
  final _minStockController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndInitializeForm();
  }

  Future<void> _loadCategoriesAndInitializeForm() async {
    setState(() {
      if (widget.product != null) {
        _nameController.text = widget.product!.name;
        _salePriceController.text = widget.product!.salePrice.toString();
        _minSalePriceController.text = widget.product!.minSalePrice.toString();
        _purchasePriceController.text = widget.product!.purchasePrice
            .toString();
        _unitController.text = widget.product!.unit;
        _measurementController.text = widget.product!.measurement;
        _minStockController.text = widget.product!.minStock.toString();
        _selectedCategoryId = widget.product!.categoryId;
      }
      _unitController.text = ProductUnitData.unitItems.first.value!;
    });
  }
// 
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _salePriceController.dispose();
    _minSalePriceController.dispose();
    _purchasePriceController.dispose();
    _unitController.dispose();
    _measurementController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final now = DateTime.now();
        final userId = await UserService.getUserId();

        final product = ProductModel(
          code: now.microsecond.toString(),
          userId: userId ?? '',
          id: widget.product?.id ?? '',
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          categoryName: _getCategoryName(_selectedCategoryId),
          salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
          minSalePrice: double.tryParse(_minSalePriceController.text) ?? 0.0,
          purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
          currentStock: 0,
          minStock: int.tryParse(_minStockController.text) ?? 0,
          maxStock: null,
          unit: _unitController.text.trim(),
          measurement: _measurementController.text.trim(),
          isActive: widget.product?.isActive ?? true,
          createdAt: widget.product?.createdAt ?? now,
          updatedAt: now,
          deletedAt: widget.product?.deletedAt,
        );
        widget.onSubmit(product);
      } catch (e) {}
    } else {
      // Form validation failed
    }
  }

  String? _getCategoryName(String? categoryId) {
    if (categoryId == null) return null;
    final category = widget.categoryList.firstWhere(
      (cat) => cat.id == categoryId,
    );
    return category.name;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 16,
            children: [
              // SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product == null ? 'إضافة منتج جديد' : 'تحديث المنتج',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم المنتج مطلوب';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String?>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('بدون فئة'),
                  ),
                  ...widget.categoryList.map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'سعر البيع *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'سعر البيع مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'سعر غير صحيح';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minSalePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أقل سعر بيع',
                        prefixIcon: Icon(Icons.money_off),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'شراء*',
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'سعر الشراء مطلوب';
                  }
                  if (double.tryParse(value) == null) {
                    return 'سعر غير صحيح';
                  }
                  return null;
                },
              ),

                    TextFormField(
                      controller: _measurementController,
                      decoration: const InputDecoration(
                        labelText: 'حجم',
                        prefixIcon: Icon(Icons.straighten),
                        hintText: 'حجم ',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  const SizedBox(width: 16),
                  DropdownButtonFormField<String>(
                    initialValue: ProductUnitData.unitItems.first.value,
                    decoration: const InputDecoration(
                      labelText: 'القياس',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: ProductUnitData.unitItems,
                    onChanged: (value) {
                      setState(() {
                        _unitController.text =
                            value ?? ProductUnitData.unitItems.first.value!;
                      });
                    },
                  ),
              //
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأدنى للمخزون',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                spacing: 20,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _submitForm();
                        Navigator.pop(context);
                      },
                      child: Text(widget.product == null ? 'إضافة' : 'تحديث'),
                    ),
                  ),
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
        ),
      ),
    );
  }
}
