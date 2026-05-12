part of 'customer_cubit.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;

  const CustomerLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomerSingleLoaded extends CustomerState {
  final CustomerModel customer;

  const CustomerSingleLoaded(this.customer);

  @override
  List<Object?> get props => [customer];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerSuccess extends CustomerState {
  final String message;

  const CustomerSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
