import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../data/models/expense_category.dart';

class ExpenseCategoriesDialog extends StatefulWidget {
  final List<ExpenseCategory> categories;
  final Function(ExpenseCategory category) onAddCategory;
  final Function(ExpenseCategory category) onUpdateCategory;
  final Function(String id) onDeleteCategory;

  const ExpenseCategoriesDialog({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  @override
  State<ExpenseCategoriesDialog> createState() => _ExpenseCategoriesDialogState();
}

class _ExpenseCategoriesDialogState extends State<ExpenseCategoriesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isAdding = false;
  ExpenseCategory? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() {
      _isAdding = true;
      _editingCategory = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  void _startEditing(ExpenseCategory category) {
    setState(() {
      _isAdding = false;
      _editingCategory = category;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
    });
  }

  void _cancelForm() {
    setState(() {
      _isAdding = false;
      _editingCategory = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = ExpenseCategory(
        id: _editingCategory?.id ?? '',
        userId: _editingCategory?.userId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: _editingCategory?.createdAt ?? DateTime.now(),
      );

      if (_editingCategory != null) {
        widget.onUpdateCategory(category);
      } else {
        widget.onAddCategory(category);
      }

      _cancelForm();
    }
  }

  void _deleteCategory(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الفئة؟'),
        actions: [
          sc.Button(
            style: sc.ButtonStyle.ghost(),
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          sc.Button(
            style: sc.ButtonStyle.destructive(),
            onPressed: () {
              widget.onDeleteCategory(id);
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فئات المصروفات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isAdding && _editingCategory == null)
                        sc.Button(
                          style: sc.ButtonStyle.primary(),
                          onPressed: _startAdding,
                          leading: const Icon(sc.LucideIcons.plus, size: 16),
                          child: const Text('فئة جديدة'),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(sc.LucideIcons.x),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Form (when adding or editing)
            if (_isAdding || _editingCategory != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingCategory != null ? 'تعديل الفئة' : 'فئة جديدة',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الفئة *',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'اسم الفئة مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'وصف (اختياري)',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: sc.Button(
                              style: sc.ButtonStyle.outline(),
                              onPressed: _cancelForm,
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: sc.Button(
                              style: sc.ButtonStyle.primary(),
                              onPressed: _submit,
                              child: Text(
                                _editingCategory != null ? 'حفظ' : 'إضافة',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // Categories list
            Expanded(
              child: widget.categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            sc.LucideIcons.folderOpen,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد فئات',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أضف فئة جديدة للبدء',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.categories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = widget.categories[index];
                        return ListTile(
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: category.description != null
                              ? Text(
                                  category.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _startEditing(category),
                                icon: const Icon(sc.LucideIcons.pencil, color: AppColors.text),
                              ),
                              IconButton(
                                onPressed: () => _deleteCategory(category.id),
                                icon: const Icon(sc.LucideIcons.trash2, color: AppColors.error),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
