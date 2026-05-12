import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/models/product_category.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;
  List<ProductModel> _allProducts = [];
  List<ProductCategory> _categories = [];
  String _selectedCategoryId = 'all';
  
  // Real-time stream subscriptions
  StreamSubscription<Either<Failure, List<ProductModel>>>? _productsSubscription;
  StreamSubscription<Either<Failure, List<ProductCategory>>>? _categoriesSubscription;

  ProductCubit({required ProductRepository productRepository}) 
      : _repository = productRepository, 
        super(ProductInitial()) {
    _startRealtimeListeners();
  }

  // Getters
  String get selectedCategoryId => _selectedCategoryId;
  List<ProductCategory> get categories => _categories;
  List<ProductModel> get filteredProducts {
    if (_selectedCategoryId == 'all') {
      return _allProducts;
    }
    return _allProducts.where((product) => product.categoryId?.toString() == _selectedCategoryId).toList();
  }

  // Products
  Future<void> getProducts() async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.getProducts();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) {
        _allProducts = products;
        emit(ProductsLoaded(products));
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

  Future<void> createProduct(ProductModel product) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.createProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (createdProduct) {
        if (isClosed) return;
        emit(ProductSuccess('Product created successfully'));
        getProducts(); // Refresh list
      },
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.updateProduct(product);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (updatedProduct) {
        if (isClosed) return;
        emit(ProductSuccess('Product updated successfully'));
        getProducts(); // Refresh list
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.deleteProduct(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ProductSuccess('Product deleted successfully'));
        getProducts(); // Refresh list
      },
    );
  }

  Future<void> searchProducts(String query) async {
    if (isClosed) return;
    emit(ProductLoading());
    final result = await _repository.searchProducts(query);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
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
        _categories = categories;
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

  // Filter methods
  void setCategoryFilter(String categoryId) {
    _selectedCategoryId = categoryId;
    // Emit current products with new filter
    emit(ProductsLoaded(filteredProducts));
  }

  void clearCategoryFilter() {
    _selectedCategoryId = 'all';
    emit(ProductsLoaded(_allProducts));
  }

  // Get products by category (for backward compatibility)
  Future<void> getProductsByCategory(String categoryId) async {
    setCategoryFilter(categoryId);
  }

  // Load initial data
  Future<void> loadInitialData() async {
    await Future.wait([
      getProducts(),
      getCategories(),
    ]);
  }

  // Real-time listeners
  void _startRealtimeListeners() {
    // Listen to products changes
    _productsSubscription = _repository.watchProducts().listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(ProductError(failure.message)),
          (products) {
            _allProducts = products;
            emit(ProductsLoaded(products));
          },
        );
      },
      onError: (error) {
        if (isClosed) return;
        emit(ProductError('Real-time products error: ${error.toString()}'));
      },
    );

    // Listen to categories changes
    _categoriesSubscription = _repository.watchCategories().listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(ProductError(failure.message)),
          (categories) {
            _categories = categories;
            emit(CategoriesLoaded(categories));
          },
        );
      },
      onError: (error) {
        if (isClosed) return;
        emit(ProductError('Real-time categories error: ${error.toString()}'));
      },
    );
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
