import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  static const int pageSize = 10;

  final ProductRepository _repository;
  final DataChangeNotifier _dataChanges;
  int _dataChangeVersion = 0;

  ProductCubit({
    required ProductRepository productRepository,
    required DataChangeNotifier dataChanges,
  }) : _repository = productRepository,
       _dataChanges = dataChanges,
       super(ProductInitial()) {
    _dataChangeVersion = _dataChanges.versionOf(DataDomain.products);
    _dataChanges.addListener(_handleDataChange);
  }

  final List<ProductModel> _products = [];
  final List<ProductModel> _fullProducts = [];
  final List<ProductCategory> _categories = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  bool _pagedMode = false;

  String get selectedCategoryId => _selectedCategoryId;
  List<ProductCategory> get categories => _categories;

  /// Loads the full product list (used by invoice product pickers).
  Future<void> getProducts({bool showLoading = true}) async {
    _pagedMode = false;
    _searchQuery = '';
    final requestId = ++_requestId;
    if (showLoading && !isClosed) emit(ProductLoading());

    final result = await _repository.getProducts();
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) {
        emit(ProductError(failure.message));
        if (_hasLoaded) _emitCurrent();
      },
      (products) {
        _fullProducts
          ..clear()
          ..addAll(products);
        _products
          ..clear()
          ..addAll(_filterByCategory(_fullProducts));
        _hasMore = false;
        _hasLoaded = true;
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
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;

    if (showLoading && !isClosed) emit(ProductLoading());

    final result = await _repository.getProductsPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(ProductError(failure.message));
        if (_hasLoaded) _emitCurrent();
      },
      (page) {
        _products
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _hasLoaded = true;
        _emitLoaded();
      },
    );
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
    final snapshot = _snapshot();
    _insertOptimistic(_withOptimisticId(product));

    final result = await _repository.createProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ProductError(failure.message));
        _emitCurrent();
      },
      (_) {
        emit(ProductSuccess('Product created successfully'));
        if (_hasLoaded) _emitCurrent();
        _dataChanges.notifyChanged(DataDomain.products);
      },
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index != -1) _products[index] = product;
    final fullIndex = _fullProducts.indexWhere((item) => item.id == product.id);
    if (fullIndex != -1) _fullProducts[fullIndex] = product;
    _emitCurrent();

    final result = await _repository.updateProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ProductError(failure.message));
        _emitCurrent();
      },
      (_) {
        emit(ProductSuccess('Product updated successfully'));
        if (_hasLoaded) _emitCurrent();
        _dataChanges.notifyChanged(DataDomain.products);
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    _products.removeWhere((product) => product.id == id);
    _fullProducts.removeWhere((product) => product.id == id);
    if (_pagedMode && _offset > 0) _offset--;
    _emitCurrent();

    final result = await _repository.deleteProduct(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ProductError(failure.message));
        _emitCurrent();
      },
      (_) {
        emit(ProductSuccess('Product deleted successfully'));
        if (_hasLoaded) _emitCurrent();
        _dataChanges.notifyChanged(DataDomain.products);
      },
    );
  }

  ({List<ProductModel> products, List<ProductModel> fullProducts, int offset})
  _snapshot() => (
    products: List<ProductModel>.from(_products),
    fullProducts: List<ProductModel>.from(_fullProducts),
    offset: _offset,
  );

  void _restore(
    ({List<ProductModel> products, List<ProductModel> fullProducts, int offset})
    snapshot,
  ) {
    _products
      ..clear()
      ..addAll(snapshot.products);
    _fullProducts
      ..clear()
      ..addAll(snapshot.fullProducts);
    _offset = snapshot.offset;
  }

  ProductModel _withOptimisticId(ProductModel product) {
    if (product.id.isNotEmpty) return product;
    return product.copyWith(
      id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  void _insertOptimistic(ProductModel product) {
    if (_pagedMode) {
      if (_matchesPagedFilters(product)) _products.insert(0, product);
    } else {
      _fullProducts.insert(0, product);
      _products
        ..clear()
        ..addAll(_filterByCategory(_fullProducts));
    }
    _emitCurrent();
  }

  bool _matchesPagedFilters(ProductModel product) {
    if (_selectedCategoryId != 'all' &&
        product.categoryId != _selectedCategoryId) {
      return false;
    }
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return true;
    return product.name.toLowerCase().contains(query) ||
        product.code.toLowerCase().contains(query) ||
        (product.barcode?.toLowerCase().contains(query) ?? false);
  }

  void _emitCurrent() {
    if (isClosed) return;
    if (_pagedMode) {
      _emitLoaded();
    } else {
      emit(ProductsLoaded(List<ProductModel>.unmodifiable(_products)));
    }
  }

  void _handleDataChange() {
    if (isClosed) return;
    final version = _dataChanges.versionOf(DataDomain.products);
    if (version == _dataChangeVersion) return;
    _dataChangeVersion = version;
    if (_pagedMode) {
      loadFirstPage(showLoading: false);
    } else if (_hasLoaded || state is ProductsLoaded) {
      getProducts(showLoading: false);
    }
  }

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }

  // Categories
  Future<void> getCategories() async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.getCategories();
    if (isClosed) return;
    result.fold((failure) => emit(ProductError(failure.message)), (categories) {
      _categories
        ..clear()
        ..addAll(categories);
      emit(CategoriesLoaded(categories));
    });
  }

  Future<void> createCategory(ProductCategory category) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.createCategory(category);
    if (isClosed) return;
    result.fold((failure) => emit(ProductError(failure.message)), (
      createdCategory,
    ) {
      if (isClosed) return;
      emit(ProductSuccess('Category created successfully'));
      getCategories(); // Refresh list
      _dataChanges.notifyChanged(DataDomain.products);
    });
  }

  Future<void> updateCategory(ProductCategory category) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.updateCategory(category);
    if (isClosed) return;
    result.fold((failure) => emit(ProductError(failure.message)), (
      updatedCategory,
    ) {
      if (isClosed) return;
      emit(ProductSuccess('Category updated successfully'));
      getCategories(); // Refresh list
      _dataChanges.notifyChanged(DataDomain.products);
    });
  }

  Future<void> deleteCategory(String id) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.deleteCategory(id);
    if (isClosed) return;
    result.fold((failure) => emit(ProductError(failure.message)), (_) {
      if (isClosed) return;
      emit(ProductSuccess('Category deleted successfully'));
      getCategories(); // Refresh list
      _dataChanges.notifyChanged(DataDomain.products);
    });
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
