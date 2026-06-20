import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/presentation/widgets/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import '../bloc/product_cubit.dart';

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key, required this.onEdit, required this.onDelete});
  final Function (ProductModel product) onEdit ;
  final Function(String productId) onDelete;
  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  @override
  void initState() {
    super.initState();
    // Load initial data - real-time listeners will handle updates automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCubit>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Products list
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is ProductError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(state.message, style: TextStyle(color: AppColors.text)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<ProductCubit>().getProducts(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                        ),
                        child: const Text('أعد المحاولة'),
                      ),
                    ],
                  ),
                );
              } else if (state is ProductsLoaded) {
                final products = context.read<ProductCubit>().filteredProducts;
                
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? Icons.inventory 
                              : Icons.filter_list,
                          size: 48, 
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? 'لم يتم العثور على منتجات' 
                              : 'لا توجد منتجات في هذه الفئة',
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? 'أضف منتجك الأول' 
                              : 'حاول اختيار فئة أخرى',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => context.read<ProductCubit>().getProducts(),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCardWidget(
                        product: product ,
                        onDelete:(productId) =>widget.onDelete(productId) ,
                        onEdit:(productModel) =>widget.onEdit(productModel) ,
                        );
                    },
                  ),
                );
              } else if (state is CategoriesLoaded) {
                // Show products after categories are loaded
                final products = context.read<ProductCubit>().filteredProducts;
                
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? Icons.inventory 
                              : Icons.filter_list,
                          size: 48, 
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? 'لم يتم العثور على منتجات' 
                              : 'لا توجد منتجات في هذه الفئة',
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.read<ProductCubit>().selectedCategoryId == 'all' 
                              ? 'أضف منتجك الأول' 
                              : 'جرّب اختيار فئة أخرى',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCardWidget(
                      onDelete: (productId) => widget.onDelete(productId),
                      onEdit: (product) => widget.onEdit(product),
                      product: product);
                  },
                );
              }
              // Initial state
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ],
      ),
    );
  }
}
