import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_period.dart';

/// Dashboard tarih filtresi için yardımcı sınıf.
/// Tarih formatlama ve UI yardımcı fonksiyonları.
class DashboardFilterHelper {
  DashboardFilterHelper._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// DateTime'ı API için YYYY-MM-DD formatına çevirir.
  static String formatDateForApi(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Verilen tarihin belirtilen aralık içinde (dahil) olup olmadığını kontrol eder.
  static bool isInDateRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  /// Belirtilen yıl için varsayılan tarih aralığını döndürür.
  static DateTimeRange getDefaultDateRangeForYear(String year) {
    final yearInt = int.tryParse(year) ?? DateTime.now().year;
    return DateTimeRange(
      start: DateTime(yearInt, 1, 1),
      end: DateTime(yearInt, 12, 31),
    );
  }

  /// Seçilen periyot için API tarih aralığını döndürür.
  static DateTimeRange getRangeForPeriod({
    required DashboardPeriod period,
    required String year,
    required DateTime month,
    DateTimeRange? customDateRange,
  }) {
    switch (period) {
      case DashboardPeriod.month:
        return DateTimeRange(
          start: DateTime(month.year, month.month, 1),
          end: DateTime(month.year, month.month + 1, 0),
        );
      case DashboardPeriod.year:
        return getDefaultDateRangeForYear(year);
      case DashboardPeriod.custom:
        return customDateRange ?? getDefaultDateRangeForYear(year);
    }
  }

  /// Aktif tarih aralığını belirler.
  static DateTimeRange getActiveDateRange({
    required String selectedYear,
    DateTimeRange? customDateRange,
  }) {
    if (customDateRange != null) {
      return customDateRange;
    }
    return getDefaultDateRangeForYear(selectedYear);
  }

  /// Kullanılabilir yılları döndürür (mevcut yıl ve önceki 2 yıl).
  static List<String> getAvailableYears() {
    final currentYear = DateTime.now().year;
    return [
      currentYear.toString(),
      (currentYear - 1).toString(),
      (currentYear - 2).toString(),
    ];
  }

  /// Tarih aralığının etiketini oluşturur (UI için).
  static String getDateRangeLabel({
    required String selectedYear,
    DateTimeRange? customDateRange,
  }) {
    if (customDateRange != null) {
      return '${customDateRange.start.day}/${customDateRange.start.month} - ${customDateRange.end.day}/${customDateRange.end.month}';
    }
    return selectedYear;
  }
}
