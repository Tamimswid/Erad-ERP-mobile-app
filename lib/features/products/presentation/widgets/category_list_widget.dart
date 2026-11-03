import 'package:erad/features/products/data/models/product_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/product_cubit.dart';
import 'package:erad/core/constants/app_constants.dart';

class CategoryListWidget extends StatefulWidget {
  const CategoryListWidget({super.key});

  @override
  State<CategoryListWidget> createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends State<CategoryListWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is ProductSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
            ),
          );
        }
      },
      child: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CategoriesLoaded) {
                if (state.categories.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(sc.LucideIcons.tag, size: 64, color: AppColors.textSecondary),
                         SizedBox(height: 16),
                         Text('لا يوجد فئات'),
                         SizedBox(height: 8),
                         Text('أضف فئة جديدة للبدء'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return CategoryCard(category: category);
                  },
                );
              }
              return const SizedBox.shrink();
            },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final ProductCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: sc.Card(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: category.description != null
              ? Text(category.description!)
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(sc.LucideIcons.pencil, size: 20),
                onPressed: () {
                  _showEditCategoryDialog(context, category);
                },
              ),
              IconButton(
                icon: const Icon(sc.LucideIcons.trash2, size: 20),
                onPressed: () {
                  _showDeleteConfirmation(context, category);
                },
              ),
            ],
          ),
          onTap: () {
            _showCategoryDetails(context, category);
          },
        ),
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (category.description != null) Text('الوصف: ${category.description}'),
              Text('تم الإنشاء: ${category.createdAt.toString().split(' ')[0]}'),
              Text('الحالة: ${category.isActive ? 'نشطة' : 'غير نشطة'}'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, ProductCategory category) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قيد التطوير')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('هل أنت متأكد من حذف الفئة ${category.name}؟'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    style: sc.ButtonStyle.destructive(),
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<ProductCubit>().deleteCategory(category.id);
                    },
                    child: const Text('حذف'),
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
