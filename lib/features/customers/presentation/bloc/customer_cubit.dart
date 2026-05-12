import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:erad/features/customers/data/models/customer.dart';
import 'package:erad/features/customers/data/repositories/customer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer';
import '../../../../core/errors/failures.dart';

part 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository customerRepository;
  StreamSubscription<Either<Failure, List<CustomerModel>>>? _customersSubscription;

  CustomerCubit({required this.customerRepository}) : super(CustomerInitial()) {
    _startRealtimeListener();
  }

  void _startRealtimeListener() {
    log('CustomerCubit: Starting realtime listener...');
    // Listen to customers real-time stream
    _customersSubscription = customerRepository.watchCustomers().listen(
      (result) {
        log('CustomerCubit: Received data from stream');
        if (isClosed) return;
        result.fold(
          (failure) {
            log('CustomerCubit: Stream error - ${failure.message}');
            emit(CustomerError(failure.message));
          },
          (customers) {
            log('CustomerCubit: Loaded ${customers.length} customers');
            emit(CustomerLoaded(customers));
          },
        );
      },
      onError: (error) {
        log('CustomerCubit: Stream error - $error');
        if (!isClosed) {
          emit(CustomerError('Stream error: $error'));
        }
      },
    );
  }

  // For backward compatibility - stream auto-loads data
  Future<void> getCustomers() async {
    // Real-time stream already loads data automatically
    // This method is kept for backward compatibility
  }

  Future<void> createCustomer(CustomerModel customer) async {
    if (isClosed) return;
    final result = await customerRepository.createCustomer(customer);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (createdCustomer) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    if (isClosed) return;
    final result = await customerRepository.updateCustomer(customer);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (updatedCustomer) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> deleteCustomer(String id) async {
    if (isClosed) return;
    final result = await customerRepository.deleteCustomer(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) {
        // Real-time stream will automatically update the UI
      },
    );
  }

  Future<void> searchCustomers(String query) async {
    if (isClosed) return;
    emit(CustomerLoading());
    final result = await customerRepository.searchCustomers(query);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomerLoaded(customers)),
    );
  }

  void clearError() {
    if (isClosed) return;
    if (state is CustomerError) {
      emit(CustomerInitial());
    }
  }

  @override
  Future<void> close() {
    _customersSubscription?.cancel();
    return super.close();
  }
}
