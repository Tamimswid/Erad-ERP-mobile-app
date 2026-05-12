part of 'customer_debt_cubit.dart';

abstract class CustomerDebtState extends Equatable {
  const CustomerDebtState();

  @override
  List<Object?> get props => [];
}

class CustomerDebtInitial extends CustomerDebtState {}

class CustomerDebtLoading extends CustomerDebtState {}

class CustomerDebtLoaded extends CustomerDebtState {
  final List<CustomerDebtModel> debts;
  final List<CustomerDebtModel> filteredDebts;

  const CustomerDebtLoaded({
    required this.debts,
    required this.filteredDebts,
  });

  @override
  List<Object?> get props => [debts, filteredDebts];

  CustomerDebtLoaded copyWith({
    List<CustomerDebtModel>? debts,
    List<CustomerDebtModel>? filteredDebts,
  }) {
    return CustomerDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
    );
  }
}

class CustomerDebtError extends CustomerDebtState {
  final String message;

  const CustomerDebtError(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerDebtSuccess extends CustomerDebtState {
  final String message;

  const CustomerDebtSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentProcessing extends CustomerDebtState {}

class PaymentSuccess extends CustomerDebtState {
  final String message;

  const PaymentSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
