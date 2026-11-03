import 'package:erad/core/widgets/charts/app_chart_data.dart';

enum HomeChartRange { month, year }

class DashboardMockData {
  DashboardMockData._();

  static const List<String> _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> _weeks = [
    'الأسبوع 1',
    'الأسبوع 2',
    'الأسبوع 3',
    'الأسبوع 4',
  ];

  static const List<double> _monthlyEarnings = [
    2400000,
    3100000,
    2800000,
    4200000,
    3900000,
    4600000,
    5100000,
    4700000,
    5400000,
    5900000,
    5200000,
    6300000,
  ];

  static const List<double> _weeklyEarnings = [
    1200000,
    1650000,
    1400000,
    1900000,
  ];

  static const List<double> _monthlySales = [
    120,
    150,
    132,
    170,
    160,
    185,
    210,
    198,
    225,
    240,
    215,
    260,
  ];

  static const List<double> _weeklySales = [42, 58, 51, 67];

  // TODO: replace with API data once chart endpoints are available.
  static AppChartData earnings(HomeChartRange range) {
    return switch (range) {
      HomeChartRange.month => AppChartData(
        values: _weeklyEarnings,
        labels: _weeks,
      ),
      HomeChartRange.year => AppChartData(
        values: _monthlyEarnings,
        labels: _months,
      ),
    };
  }

  static AppChartData productSales(HomeChartRange range) {
    return switch (range) {
      HomeChartRange.month => AppChartData(
        values: _weeklySales,
        labels: _weeks,
      ),
      HomeChartRange.year => AppChartData(
        values: _monthlySales,
        labels: _months,
      ),
    };
  }
}
