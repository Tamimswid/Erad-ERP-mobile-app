import 'dart:math' as math;

class AppChartData {
  final List<double> values;
  final List<String> labels;

  AppChartData({required this.values, required this.labels})
    : assert(values.length == labels.length);

  bool get isEmpty => values.isEmpty;

  double get total => values.fold(0, (sum, value) => sum + value);

  double get maxValue =>
      values.isEmpty ? 0 : values.reduce((a, b) => math.max(a, b));
}
