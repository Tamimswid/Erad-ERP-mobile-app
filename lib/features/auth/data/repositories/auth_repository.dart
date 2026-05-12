import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:erad/features/auth/data/datasource/auth_local_datasource.dart';
import '../models/user.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepository(this.remoteDataSource, this.localDataSource, this.networkInfo);

  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      User? user;
      
      if (await networkInfo.isConnected) {
        user = await remoteDataSource.login(email, password);
        await localDataSource.cacheUser(user);
        await localDataSource.cacheUserId(user.id);
      } else {
        user = await localDataSource.getCachedUser();
        if (user == null) {
          return Left(NetworkFailure.noConnection());
        }
        final userId = await localDataSource.getCachedUserId();
        if (userId == null) {
          return Left(NetworkFailure.noConnection());
        }
      }
      
      return Right(user);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, User>> register(String email, String password, String businessName) async {
    try {
      User? user;
      
      if (await networkInfo.isConnected) {
        user = await remoteDataSource.register(email: email, password: password, businessName: businessName);
        await localDataSource.cacheUser(user);
        await localDataSource.cacheUserId(user.id);
      } else {
        return Left(NetworkFailure.noConnection());
      }
      
      return Right(user);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCachedUser();
      await localDataSource.clearCachedAuthToken();
      await localDataSource.clearCachedUserId();
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      User? user;
      
      if (await networkInfo.isConnected) {
        user = await remoteDataSource.getCurrentUser();
        if (user != null) {
          await localDataSource.cacheUser(user);
          await localDataSource.cacheUserId(user.id);
        } else {
          user = await localDataSource.getCachedUser();
          if (user == null) {
            return Left(const ServerFailure('No user found'));
          }
        }
      } else {
        user = await localDataSource.getCachedUser();
        if (user == null) {
          return Left(NetworkFailure.noConnection());
        }
      }
      
      return Right(user);
    } on Failure catch (failure) {
      try {
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Right(cachedUser);
        }
      } catch (e) {}
      return Left(failure);
    } catch (e) {
      try {
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Right(cachedUser);
        }
      } catch (cacheError) {}
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      // İnternet varsa remote'den şifre sıfırlama maili gönder
      if (await networkInfo.isConnected) {
        await remoteDataSource.forgotPassword(email);
      } else {
        // İnternet yoksa şifre sıfırlama maili gönderemezsin
        return Left(NetworkFailure.noConnection());
      }
      
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> resetPassword(String token, String password) async {
    try {
      // İnternet varsa remote'den şifreyi sıfırla
      if (await networkInfo.isConnected) {
        await remoteDataSource.resetPassword(token, password);
      } else {
        // İnternet yoksa şifreyi sıfırlayamazsın
        return Left(NetworkFailure.noConnection());
      }
      
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, User>> updateProfile(User user) async {
    try {
      User updatedUser;
      
      // İnternet varsa remote'den profili güncelle ve local'e kaydet
      if (await networkInfo.isConnected) {
        updatedUser = await remoteDataSource.updateProfile(user);
        await localDataSource.cacheUser(updatedUser);
      } else {
        // İnternet yoksa profili güncelleyemezsin
        return Left(NetworkFailure.noConnection());
      }
      
      return Right(updatedUser);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      // İnternet varsa remote'den şifre değiştir
      if (await networkInfo.isConnected) {
        await remoteDataSource.changePassword(currentPassword, newPassword);
      } else {
        // İnternet yoksa şifre değiştiremezsin
        return Left(NetworkFailure.noConnection());
      }
      
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Stream<User?> get userChanges => remoteDataSource.userChanges;
  
  bool get isAuthenticated => remoteDataSource.getCurrentUser() != null;
}
