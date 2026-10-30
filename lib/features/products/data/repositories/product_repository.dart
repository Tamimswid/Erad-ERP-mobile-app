import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../datasource/product_remote_datasource.dart';

class ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, List<ProductModel>>> getProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProducts();
        return Right(products);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductModel>> getProduct(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.getProduct(id);
        return Right(product);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, List<ProductCategory>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getCategories();
        return Right(categories);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductCategory>> getCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final category = await remoteDataSource.getCategory(id);
        return Right(category);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductModel>> createProduct(ProductModel product) async {
    if (await networkInfo.isConnected) {
      try {
        final createdProduct = await remoteDataSource.createProduct(product);
        return Right(createdProduct);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductModel>> updateProduct(ProductModel product) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedProduct = await remoteDataSource.updateProduct(product);
        return Right(updatedProduct);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, void>> deleteProduct(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteProduct(id);
        return const Right(null);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductCategory>> createCategory(ProductCategory category) async {
    if (await networkInfo.isConnected) {
      try {
        final createdCategory = await remoteDataSource.createCategory(category);
        return Right(createdCategory);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, ProductCategory>> updateCategory(ProductCategory category) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedCategory = await remoteDataSource.updateCategory(category);
        return Right(updatedCategory);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, void>> deleteCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);
        return const Right(null);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, List<ProductModel>>> searchProducts(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.searchProducts(query);
        return Right(products);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, List<ProductModel>>> getProductsByCategory(String categoryId) async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProductsByCategory(categoryId);
        return Right(products);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // Real-time streams
  Stream<Either<Failure, List<ProductModel>>> watchProducts() {
    try {
      return remoteDataSource.watchProducts().map((products) => Right(products));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }

  Stream<Either<Failure, List<ProductCategory>>> watchCategories() {
    try {
      return remoteDataSource.watchCategories().map((categories) => Right(categories));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }
}
