import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/presentation/widgets/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/product_cubit.dart';

class ProductListWidget extends StatelessWidget {
  const ProductListWidget({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final Function(ProductModel product) onEdit;
  final Function(String productId) onDelete;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductCubit>();

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sc.LucideIcons.circleAlert,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.text)),
                const SizedBox(height: 16),
                sc.Button(
                  alignment: Alignment.center,
                  style: sc.ButtonStyle.primary(),
                  onPressed: () => cubit.loadFirstPage(),
                  child: const Text('أعد المحاولة'),
                ),
              ],
            ),
          );
        }

        final products = state is ProductsLoaded
            ? state.products
            : const <ProductModel>[];
        final hasMore = state is ProductsLoaded && state.hasMore;
        final isLoadingMore = state is ProductsLoaded && state.isLoadingMore;

        if (products.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => cubit.loadFirstPage(showLoading: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(cubit.selectedCategoryId == 'all'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => cubit.loadFirstPage(showLoading: false),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppPaginationSliverList(
                itemCount: products.length,
                hasMore: hasMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: cubit.loadMore,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                separator: const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCardWidget(
                    product: product,
                    onDelete: (productId) => onDelete(productId),
                    onEdit: (productModel) => onEdit(productModel),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAllCategories) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAllCategories
                ? sc.LucideIcons.package
                : sc.LucideIcons.listFilter,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            isAllCategories
                ? 'لم يتم العثور على منتجات'
                : 'لا توجد منتجات في هذه الفئة',
            style: TextStyle(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            isAllCategories ? 'أضف منتجك الأول' : 'حاول اختيار فئة أخرى',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
