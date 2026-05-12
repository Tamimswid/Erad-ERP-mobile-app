part of 'product_cubit.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductsLoaded extends ProductState {
  final List<ProductModel> products;

  const ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductSingleLoaded extends ProductState {
  final ProductModel product;

  const ProductSingleLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class CategoriesLoaded extends ProductState {
  final List<ProductCategory> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductSuccess extends ProductState {
  final String message;

  const ProductSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
