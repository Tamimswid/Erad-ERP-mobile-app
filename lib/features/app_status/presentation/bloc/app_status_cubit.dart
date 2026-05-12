import 'package:bloc/bloc.dart';
import 'package:erad/features/app_status/data/repositories/app_status_repository.dart';

part 'app_status_state.dart';

class AppStatusCubit extends Cubit<AppStatusState> {
  final AppStatusRepository repository;

  AppStatusCubit({required this.repository}) : super(AppStatusInitial());

  Future<void> checkAppStatus() async {
    emit(AppStatusLoading());
    
    final result = await repository.checkAppStatus();
    
    result.fold(
      (failure) => emit(AppStatusError(failure.message)),
      (isActive) => emit(AppStatusChecked(isActive: isActive)),
    );
  }
}
