import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/di/services_locator.dart';
import 'package:erad/core/widgets/app_pagination_list.dart';
import 'package:erad/core/widgets/app_stat_tile.dart';
import 'package:erad/core/widgets/date_range_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../data/models/stock_review_item.dart';
import '../bloc/stock_review_cubit.dart';

class StockReviewPage extends StatefulWidget {
  const StockReviewPage({super.key});

  @override
  State<StockReviewPage> createState() => _StockReviewPageState();
}

class _StockReviewPageState extends State<StockReviewPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StockReviewCubit>()..loadInitial(),
      child: sc.Scaffold(
        headers: [
          sc.AppBar(
            title: const Text('مراجعة المخزون'),
            leading: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(sc.LucideIcons.arrowRight, size: 22),
              ),
            ],
          ),
        ],
        child: BlocConsumer<StockReviewCubit, StockReviewState>(
          listener: (context, state) {
            if (state is StockReviewError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<StockReviewCubit>();
            return Column(
              children: [
                _buildSearchField(cubit),
                _buildCategoryChips(cubit),
                Expanded(child: _buildBody(cubit, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField(StockReviewCubit cubit) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                cubit.updateSearch(value);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14, color: scheme.foreground),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: scheme.mutedForeground,
                ),
                prefixIcon: Icon(
                  sc.LucideIcons.search,
                  size: 18,
                  color: scheme.mutedForeground,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          cubit.updateSearch('');
                          setState(() {});
                        },
                        icon: Icon(
                          sc.LucideIcons.x,
                          size: 16,
                          color: scheme.mutedForeground,
                        ),
                      ),
                filled: true,
                fillColor: scheme.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppDateRangeFilterButton(
            compact: true,
            range: cubit.dateRange,
            onPressed: () => _openDateFilter(cubit),
          ),
        ],
      ),
    );
  }

  Future<void> _openDateFilter(StockReviewCubit cubit) async {
    final result = await AppDateRangeSheet.show(
      context,
      initialRange: cubit.dateRange,
      title: 'تصفية حسب التاريخ',
    );
    if (result == null || !mounted) return;
    await cubit.setDateRange(result.range);
  }

  Widget _buildCategoryChips(StockReviewCubit cubit) {
    final categories = cubit.categories;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            label: 'الكل',
            isSelected: cubit.selectedCategoryId == null,
            onTap: () => cubit.selectCategory(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _buildChip(
              label: category.name,
              isSelected: cubit.selectedCategoryId == category.id,
              onTap: () => cubit.selectCategory(category.id),
            ),
          ],
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

  Widget _buildBody(StockReviewCubit cubit, StockReviewState state) {
    if (state is StockReviewInitial || state is StockReviewLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is StockReviewError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sc.LucideIcons.circleAlert,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              sc.Button(
                alignment: Alignment.center,
                style: sc.ButtonStyle.primary(),
                onPressed: cubit.reload,
                leading: const Icon(sc.LucideIcons.refreshCw, size: 16),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is! StockReviewLoaded) {
      return const SizedBox.shrink();
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              sc.LucideIcons.packageSearch,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد منتجات',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final countLabel = state.hasMore
        ? '${state.items.length}+ منتج'
        : '${state.items.length} منتج';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              countLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        AppPaginationSliverList(
          itemCount: state.items.length,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: cubit.loadMore,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separator: const SizedBox(height: 8),
          bottomSpace: 32,
          itemBuilder: (context, index) =>
              _StockItemCard(item: state.items[index]),
        ),
      ],
    );
  }
}

class _StockItemCard extends StatelessWidget {
  const _StockItemCard({required this.item});

  final StockReviewItem item;

  @override
  Widget build(BuildContext context) {
    final remainingColor = _remainingColor(item.calculatedRemainingStock);

    return sc.Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: AppColors.divider,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName.isEmpty ? 'بدون اسم' : item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: remainingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'المتبقي ${item.calculatedRemainingStock}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: remainingColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  label: 'المسجل',
                  value: '${item.systemStock}',
                ),
              ),
              Expanded(
                child: AppStatTile(
                  label: 'المشترى',
                  value: '${item.totalPurchasedQty}',
                ),
              ),
              Expanded(
                child: AppStatTile(
                  label: 'المباع',
                  value: '${item.totalSoldQty}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _remainingColor(int remaining) {
    if (remaining <= 0) return AppColors.error;
    if (remaining <= StockReviewCubit.lowStockWarningThreshold) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}
