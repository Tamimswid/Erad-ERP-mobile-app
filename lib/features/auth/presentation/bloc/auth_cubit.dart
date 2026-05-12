import 'package:erad/features/auth/data/models/user.dart';
import 'package:erad/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await authRepository.login(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> register(String email, String password, String businessName) async {
    emit(AuthLoading());
    final result = await authRepository.register(email, password, businessName);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthRegistered(userId: user.id, email: user.email)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await authRepository.logout();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> getCurrentUser() async {
    emit(AuthLoading());
    final result = await authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) {
        emit(Authenticated(user));
      },
    );
  }

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    final result = await authRepository.forgotPassword(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthSuccess('تم إرسال رابط استعادة كلمة المرور')),
    );
  }

  Future<void> resetPassword(String token, String password) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(token, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthSuccess('تم إعادة تعيين كلمة المرور بنجاح')),
    );
  }

  Future<void> updateProfile(User user) async {
    emit(AuthLoading());
    final result = await authRepository.updateProfile(user);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    emit(AuthLoading());
    final result = await authRepository.changePassword(currentPassword, newPassword);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthSuccess('تم تغيير كلمة المرور بنجاح')),
    );
  }
}
