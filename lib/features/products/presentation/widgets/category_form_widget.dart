import 'package:erad/core/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../data/models/product_category.dart';
import '../bloc/product_cubit.dart';

class CategoryFormWidget extends StatefulWidget {
  final ProductCategory? category;

  const CategoryFormWidget({super.key, this.category});

  @override
  State<CategoryFormWidget> createState() => _CategoryFormWidgetState();
}

class _CategoryFormWidgetState extends State<CategoryFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveCategory() async{
    if (_formKey.currentState!.validate()) {
      final category = ProductCategory(
        userId: await UserService.getUserId() ?? '',
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isActive: true,
        createdAt: widget.category?.createdAt ?? DateTime.now(),

      );

      if (widget.category == null) {
        context.read<ProductCubit>().createCategory(category);
      } else {
        context.read<ProductCubit>().updateCategory(category);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم الفئة *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(sc.LucideIcons.tag),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم الفئة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: sc.Button(
                  style: sc.ButtonStyle.outline(),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: sc.Button(
                  style: sc.ButtonStyle.primary(),
                  onPressed: _saveCategory,
                  child: Text(widget.category == null ? 'إضافة' : 'حفظ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
