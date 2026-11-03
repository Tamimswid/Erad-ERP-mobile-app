class WithdrawalSummary {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final List<double> monthlyData;

  const WithdrawalSummary({
    this.totalAmount = 0,
    this.totalCount = 0,
    this.averageAmount = 0,
    this.monthlyData = const [],
  });
}
