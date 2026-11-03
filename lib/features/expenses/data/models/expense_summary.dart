class ExpenseSummary {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final Map<String, double> monthlyData;

  const ExpenseSummary({
    this.totalAmount = 0,
    this.totalCount = 0,
    this.averageAmount = 0,
    this.monthlyData = const {},
  });
}
