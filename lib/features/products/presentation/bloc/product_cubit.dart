import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  static const int pageSize = 10;

  final ProductRepository _repository;

  ProductCubit({required ProductRepository productRepository})
      : _repository = productRepository,
        super(ProductInitial());

  final List<ProductModel> _products = [];
  final List<ProductModel> _fullProducts = [];
  final List<ProductCategory> _categories = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _pagedMode = false;

  String get selectedCategoryId => _selectedCategoryId;
  List<ProductCategory> get categories => _categories;

  /// Loads the full product list (used by invoice product pickers).
  Future<void> getProducts() async {
    _pagedMode = false;
    _searchQuery = '';
    final requestId = ++_requestId;
    if (!isClosed) emit(ProductLoading());

    final result = await _repository.getProducts();
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) {
        _fullProducts
          ..clear()
          ..addAll(products);
        _products
          ..clear()
          ..addAll(_filterByCategory(_fullProducts));
        emit(ProductsLoaded(List<ProductModel>.unmodifiable(_products)));
      },
    );
  }

  Future<void> getProduct(String id) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.getProduct(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductSingleLoaded(product)),
    );
  }

  /// Loads the first page for the paginated products page.
  Future<void> loadFirstPage({bool showLoading = true}) async {
    _pagedMode = true;
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _products.clear();

    if (showLoading && !isClosed) emit(ProductLoading());

    final result = await _repository.getProductsPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold((failure) => emit(ProductError(failure.message)), (page) {
      _products.addAll(page.items);
      _offset = page.items.length;
      _hasMore = page.hasMore;
      _emitLoaded();
    });
  }

  Future<void> loadMore() async {
    if (!_pagedMode || isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await _repository.getProductsPage(
      offset: _offset,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (_) {
        _isLoadingMore = false;
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _products.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      ProductsLoaded(
        List<ProductModel>.unmodifiable(_products),
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    await loadFirstPage(showLoading: false);
  }

  Future<void> createProduct(ProductModel product) async {
    if (isClosed) return;
    final result = await _repository.createProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ProductSuccess('Product created successfully'));
        _refreshAfterMutation();
      },
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    if (isClosed) return;
    final result = await _repository.updateProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ProductSuccess('Product updated successfully'));
        _refreshAfterMutation();
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    if (isClosed) return;
    final result = await _repository.deleteProduct(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ProductSuccess('Product deleted successfully'));
        _refreshAfterMutation();
      },
    );
  }

  void _refreshAfterMutation() {
    if (_pagedMode) {
      loadFirstPage(showLoading: false);
    } else {
      getProducts();
    }
  }

  // Categories
  Future<void> getCategories() async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.getCategories();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (categories) {
        _categories
          ..clear()
          ..addAll(categories);
        emit(CategoriesLoaded(categories));
      },
    );
  }

  Future<void> createCategory(ProductCategory category) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.createCategory(category);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (createdCategory) {
        if (isClosed) return;
        emit(ProductSuccess('Category created successfully'));
        getCategories(); // Refresh list
      },
    );
  }

  Future<void> updateCategory(ProductCategory category) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.updateCategory(category);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (updatedCategory) {
        if (isClosed) return;
        emit(ProductSuccess('Category updated successfully'));
        getCategories(); // Refresh list
      },
    );
  }

  Future<void> deleteCategory(String id) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.deleteCategory(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ProductSuccess('Category deleted successfully'));
        getCategories(); // Refresh list
      },
    );
  }

  Future<void> setCategoryFilter(String categoryId) async {
    _selectedCategoryId = categoryId;
    if (_pagedMode) {
      await loadFirstPage(showLoading: false);
    } else if (!isClosed) {
      _products
        ..clear()
        ..addAll(_filterByCategory(_fullProducts));
      emit(ProductsLoaded(List<ProductModel>.unmodifiable(_products)));
    }
  }

  Future<void> clearCategoryFilter() => setCategoryFilter('all');

  Future<void> getProductsByCategory(String categoryId) =>
      setCategoryFilter(categoryId);

  List<ProductModel> _filterByCategory(List<ProductModel> products) {
    if (_selectedCategoryId == 'all') return List<ProductModel>.of(products);
    return products
        .where((product) => product.categoryId == _selectedCategoryId)
        .toList();
  }
}
