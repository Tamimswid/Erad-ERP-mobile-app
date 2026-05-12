import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/customer.dart';
import '../datasource/customer_remote_datasource.dart';

// مستودع العملاء - يتحقق من الاتصال بالشبكة ويعالج الأخطاء
class CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CustomerRepository(this.remoteDataSource, this.networkInfo);

  // جلب جميع العملاء مع التحقق من الاتصال
  Future<Either<Failure, List<CustomerModel>>> getCustomers() async {
    if (await networkInfo.isConnected) {
      try {
        final customers = await remoteDataSource.getCustomers();
        return Right(customers);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // Stream للعملاء في الوقت الفعلي
  Stream<Either<Failure, List<CustomerModel>>> watchCustomers() {
    return remoteDataSource.watchCustomers().map(
          (customers) => Right<Failure, List<CustomerModel>>(customers),
        ).handleError(
          (error) => Left<Failure, List<CustomerModel>>(exceptionToFailure(error)),
        );
  }

  // جلب عميل بالمعرف مع التحقق من الاتصال
  Future<Either<Failure, CustomerModel>> getCustomer(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final customer = await remoteDataSource.getCustomer(id);
        return Right(customer);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // إنشاء عميل جديد مع التحقق من الاتصال
  Future<Either<Failure, CustomerModel>> createCustomer(CustomerModel customer) async {
    if (await networkInfo.isConnected) {
      try {
        final createdCustomer = await remoteDataSource.createCustomer(customer);
        return Right(createdCustomer);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // تحديث بيانات العميل مع التحقق من الاتصال
  Future<Either<Failure, CustomerModel>> updateCustomer(CustomerModel customer) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedCustomer = await remoteDataSource.updateCustomer(customer);
        return Right(updatedCustomer);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // حذف عميل مع التحقق من الاتصال
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCustomer(id);
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

  // البحث عن العملاء مع التحقق من الاتصال
  Future<Either<Failure, List<CustomerModel>>> searchCustomers(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final customers = await remoteDataSource.searchCustomers(query);
        return Right(customers);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }
}
