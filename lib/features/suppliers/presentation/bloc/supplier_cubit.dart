import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';
import '../../../../core/errors/failures.dart';
import '../../data/models/supplier.dart';
import '../../data/repositories/supplier_repository.dart';

part 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository supplierRepository;
  StreamSubscription<Either<Failure, List<SupplierModel>>>? _suppliersSubscription;

  SupplierCubit({required this.supplierRepository}) : super(SupplierInitial()) {
    _startRealtimeListener();
  }

  void _startRealtimeListener() {
    log('SupplierCubit: Starting realtime listener...');
    // Listen to suppliers real-time stream
    _suppliersSubscription = supplierRepository.watchSuppliers().listen(
      (result) {
        log('SupplierCubit: Received data from stream');
        if (isClosed) return;
        result.fold(
          (failure) {
            log('SupplierCubit: Stream error - ${failure.message}');
            emit(SupplierError(failure.message));
          },
          (suppliers) {
            log('SupplierCubit: Loaded ${suppliers.length} suppliers');
            emit(SuppliersLoaded(suppliers));
          },
        );
      },
      onError: (error) {
        log('SupplierCubit: Stream error - $error');
        if (!isClosed) {
          emit(SupplierError('Stream error: $error'));
        }
      },
    );
  }

  // For backward compatibility - stream auto-loads data
  Future<void> getSuppliers() async {
    // Real-time stream already loads data automatically
  }

  Future<void> createSupplier(SupplierModel supplier) async {
    if (isClosed) return;
    final result = await supplierRepository.createSupplier(supplier);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (createdSupplier) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (isClosed) return;
    final result = await supplierRepository.updateSupplier(supplier);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (updatedSupplier) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> deleteSupplier(String id) async {
    if (isClosed) return;
    final result = await supplierRepository.deleteSupplier(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> searchSuppliers(String query) async {
    if (isClosed) return;
    emit(SupplierLoading());
    final result = await supplierRepository.searchSuppliers(query);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (suppliers) => emit(SuppliersLoaded(suppliers)),
    );
  }

  void clearError() {
    if (isClosed) return;
    if (state is SupplierError) {
      emit(SupplierInitial());
    }
  }

  @override
  Future<void> close() {
    _suppliersSubscription?.cancel();
    return super.close();
  }
}
