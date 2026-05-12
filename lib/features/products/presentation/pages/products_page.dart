import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/presentation/widgets/category_list_widget.dart';
import 'package:erad/features/products/presentation/widgets/category_form_widget.dart';
import 'package:erad/features/products/presentation/widgets/product_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_cubit.dart';
import '../widgets/product_list_widget.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
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
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل المنتجات والفئات بالتوازي
      await Future.wait([
        _productCubit.getProducts(),
        _productCubit.getCategories(),
      ]);

      // الاستماع لحالة تحميل الفئات
      if (mounted) {
        final state = _productCubit.state;
        if (state is CategoriesLoaded) {
          setState(() {
            _categories = state.categories;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<ProductCubit, ProductState>(
          listener: (context, state) {
            if (state is CategoriesLoaded) {
              setState(() {
                _categories = state.categories;
                _isLoading = false;
              });
            } else if (state is ProductError) {
              // Show error for real-time updates
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ProductSuccess) {
              // Show success for CRUD operations
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with search, categories and category chips
                _buildHeader(context, state),
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
                        onSubmit: (product) => _productCubit.updateProduct(product),
                        categoryList: _categories,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text(
            'إنشاء المنتج',
            style: TextStyle(color: AppColors.background),
          ),
          backgroundColor: AppColors.primary,
          onPressed: () {
            _showAddProductDialog(
              context: context,
              onSubmit: (product) => _productCubit.createProduct(product),
              categoryList: _categories,
            );
          },
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
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'اسم المنتج أو الكود',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
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
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocProvider(
                    create: (context) => sl<ProductCubit>(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddCategoryDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة فئة جديدة'),
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
      builder: (context) => Dialog(
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: BlocProvider(
                    create: (context) => sl<ProductCubit>(),
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
              Icon(Icons.warning_outlined, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text('تأكيد الحذف'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete(productId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProductState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with search and categories buttons
          Row(
            children: [
              const Text(
                'المنتجات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              // Search button
              _buildIconButton(
                icon: Icons.search,
                onTap: () => _showSearchDialog(context),
              ),
              const SizedBox(width: 8),
              // Categories button
              _buildIconButton(
                icon: Icons.category_outlined,
                onTap: () => _showCategoriesDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category chips
          _buildCategoryChips(context, state),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
