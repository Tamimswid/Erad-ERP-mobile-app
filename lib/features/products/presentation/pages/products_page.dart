import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/presentation/widgets/category_list_widget.dart';
import 'package:erad/features/products/presentation/widgets/category_form_widget.dart';
import 'package:erad/features/products/presentation/widgets/product_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/product_cubit.dart';
import '../widgets/product_list_widget.dart';

class ProductsPage extends StatefulWidget {
  final bool isLocal;

  const ProductsPage({super.key, this.isLocal = false});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductCategory> _categories = [];
  late ProductCubit _productCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _productCubit = sl<ProductCubit>();

    // تحميل البيانات فوراً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _productCubit.getCategories();
    await _productCubit.loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productCubit,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المنتجات'),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
            ),
            actions: [
              IconButton(
                onPressed: () => _showSearchDialog(context),
                icon: const Icon(sc.LucideIcons.search, size: 20),
              ),
              IconButton(
                onPressed: () => _showCategoriesDialog(context),
                icon: const Icon(sc.LucideIcons.folderOpen, size: 20),
              ),
            ],
          ),
          body: BlocConsumer<ProductCubit, ProductState>(
            listener: (context, state) {
              if (state is CategoriesLoaded) {
                setState(() {
                  _categories = state.categories;
                });
              } else if (state is ProductError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is ProductSuccess) {
                // Show success for CRUD operations
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  // Category chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: _buildCategoryChips(context, state),
                  ),
                  // Products list
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: ProductListWidget(
                        onDelete: (productId) => _showDeleteConfirmationDialog(
                          onDelete: (productId) =>
                              _productCubit.deleteProduct(productId),
                          productId: productId,
                        ),
                        onEdit: (product) => _showAddProductDialog(
                          product: product,
                          context: context,
                          onSubmit: (product) =>
                              _productCubit.updateProduct(product),
                          categoryList: _categories,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: widget.isLocal
              ? null
              : FloatingActionButton.extended(
            label: const Text('إنشاء المنتج'),
            onPressed: () {
              _showAddProductDialog(
                context: context,
                onSubmit: (product) => _productCubit.createProduct(product),
                categoryList: _categories,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث عن منتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج أو الكود',
                  prefixIcon: Icon(sc.LucideIcons.search),
                ),
              ),
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
                    style: sc.ButtonStyle.primary(),
                    onPressed: () {
                      if (searchController.text.trim().isNotEmpty) {
                        context.read<ProductCubit>().searchProducts(
                          searchController.text.trim(),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('بحث'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الفئات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sc.IconButton(
                      variance: sc.ButtonStyle.ghost(),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(sc.LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocProvider.value(
                    value: _productCubit,
                    child: Column(
                      children: [
                        if (!widget.isLocal)
                          Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: sc.Button(
                              style: sc.ButtonStyle.primary(),
                              onPressed: () =>
                                  _showAddCategoryDialog(dialogContext),
                              leading: const Icon(sc.LucideIcons.plus, size: 18),
                              child: const Text('إضافة فئة جديدة'),
                            ),
                          ),
                        ),
                        const Expanded(child: CategoryListWidget()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog({
    required BuildContext context,
    required Function(ProductModel product) onSubmit,
    required List<ProductCategory> categoryList,
    ProductModel? product,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Expanded(
                child: ProductFormWidget(
                  product: product,
                  onSubmit: (product) => onSubmit(product),
                  categoryList: categoryList,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 600,
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إضافة فئة جديدة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sc.IconButton(
                      variance: sc.ButtonStyle.ghost(),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(sc.LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: BlocProvider.value(
                    value: _productCubit,
                    child: const CategoryFormWidget(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog({
    required Function(String productId) onDelete,
    required String productId,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(sc.LucideIcons.triangleAlert, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('تأكيد الحذف'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('هل أنت متأكد من حذف هذا المنتج؟'),
              const SizedBox(height: 12),
              const Text(
                'سيتم حذف جميع البيانات المرتبطة بهذا المنتج:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• عناصر فواتير البيع'),
              const Text('• عناصر فواتير الشراء'),
              const SizedBox(height: 8),
              const Text(
                'هذا الإجراء لا يمكن التراجع عنه',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
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
                      onDelete(productId);
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context, ProductState state) {
    final cubit = context.read<ProductCubit>();
    final categories = cubit.categories;
    final selectedCategory = cubit.selectedCategoryId;

    if (state is ProductLoading && categories.isEmpty) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // All products chip
          _buildChip(
            label: 'الكل',
            isSelected: selectedCategory == 'all',
            onTap: () => cubit.setCategoryFilter('all'),
          ),
          const SizedBox(width: 8),
          // Category chips
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: category.name,
                isSelected: selectedCategory == category.id,
                onTap: () => cubit.setCategoryFilter(category.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
