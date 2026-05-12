part of 'app_status_cubit.dart';

abstract class AppStatusState {}

class AppStatusInitial extends AppStatusState {}

class AppStatusLoading extends AppStatusState {}

class AppStatusError extends AppStatusState {
  final String message;
  AppStatusError(this.message);
}

class AppStatusChecked extends AppStatusState {
  final bool isActive;
  AppStatusChecked({required this.isActive});
}
