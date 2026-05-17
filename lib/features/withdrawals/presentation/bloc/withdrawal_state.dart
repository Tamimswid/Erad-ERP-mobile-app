part of 'withdrawal_cubit.dart';

abstract class WithdrawalState extends Equatable {
  const WithdrawalState();

  @override
  List<Object?> get props => [];
}

class WithdrawalInitial extends WithdrawalState {}

class WithdrawalLoading extends WithdrawalState {}

class WithdrawalsLoaded extends WithdrawalState {
  final List<Withdrawal> withdrawals;
  final List<Partner> partners;
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final List<double> monthlyData;
  final String? selectedPartnerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedYear;

  const WithdrawalsLoaded({
    required this.withdrawals,
    required this.partners,
    this.totalAmount = 0,
    this.totalCount = 0,
    this.averageAmount = 0,
    this.monthlyData = const [],
    this.selectedPartnerId,
    this.startDate,
    this.endDate,
    this.selectedYear,
  });

  WithdrawalsLoaded copyWith({
    List<Withdrawal>? withdrawals,
    List<Partner>? partners,
    double? totalAmount,
    int? totalCount,
    double? averageAmount,
    List<double>? monthlyData,
    String? selectedPartnerId,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedYear,
    bool clearSelectedPartner = false,
    bool clearDates = false,
  }) {
    return WithdrawalsLoaded(
      withdrawals: withdrawals ?? this.withdrawals,
      partners: partners ?? this.partners,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCount: totalCount ?? this.totalCount,
      averageAmount: averageAmount ?? this.averageAmount,
      monthlyData: monthlyData ?? this.monthlyData,
      selectedPartnerId: clearSelectedPartner ? null : (selectedPartnerId ?? this.selectedPartnerId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  @override
  List<Object?> get props => [
        withdrawals,
        partners,
        totalAmount,
        totalCount,
        averageAmount,
        monthlyData,
        selectedPartnerId,
        startDate,
        endDate,
        selectedYear,
      ];
}

class WithdrawalSuccess extends WithdrawalState {
  final String message;

  const WithdrawalSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class WithdrawalError extends WithdrawalState {
  final String message;

  const WithdrawalError(this.message);

  @override
  List<Object?> get props => [message];
}
