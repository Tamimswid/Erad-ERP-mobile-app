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
  final CustomerDebtTotalsModel totals;

  const CustomerDebtLoaded({
    required this.debts,
    required this.filteredDebts,
    this.totals = const CustomerDebtTotalsModel(),
  });

  @override
  List<Object?> get props => [debts, filteredDebts, totals];

  CustomerDebtLoaded copyWith({
    List<CustomerDebtModel>? debts,
    List<CustomerDebtModel>? filteredDebts,
    CustomerDebtTotalsModel? totals,
  }) {
    return CustomerDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      totals: totals ?? this.totals,
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
