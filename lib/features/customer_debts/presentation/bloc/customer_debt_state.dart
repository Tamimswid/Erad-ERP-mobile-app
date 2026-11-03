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
  final int debtorCount;
  final bool hasMore;
  final bool isLoadingMore;

  const CustomerDebtLoaded({
    required this.debts,
    required this.filteredDebts,
    this.totals = const CustomerDebtTotalsModel(),
    this.debtorCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    debts,
    filteredDebts,
    totals,
    debtorCount,
    hasMore,
    isLoadingMore,
  ];

  CustomerDebtLoaded copyWith({
    List<CustomerDebtModel>? debts,
    List<CustomerDebtModel>? filteredDebts,
    CustomerDebtTotalsModel? totals,
    int? debtorCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CustomerDebtLoaded(
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      totals: totals ?? this.totals,
      debtorCount: debtorCount ?? this.debtorCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
