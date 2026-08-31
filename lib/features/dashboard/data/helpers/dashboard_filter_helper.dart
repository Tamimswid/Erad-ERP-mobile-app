import 'package:flutter/material.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/invoice_status.dart';

import 'package:intl/intl.dart';

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
  /// 
  /// Başlangıç ve bitiş tarihleri dahildir (!isBefore / !isAfter kullanır).
  static bool isInDateRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  /// Belirtilen yıl için varsayılan tarih aralığını döndürür.
  /// 
  /// Yıl başından yıl sonuna kadar (1 Ocak - 31 Aralık) aralık döndürür.
  static DateTimeRange getDefaultDateRangeForYear(String year) {
    final yearInt = int.tryParse(year) ?? DateTime.now().year;
    return DateTimeRange(
      start: DateTime(yearInt, 1, 1),
      end: DateTime(yearInt, 12, 31),
    );
  }

  /// Aktif tarih aralığını belirler.
  /// 
  /// Custom date range varsa onu, yoksa yıl bazlı varsayılan aralığı döndürür.
  static DateTimeRange getActiveDateRange({
    required String selectedYear,
    DateTimeRange? customDateRange,
  }) {
    if (customDateRange != null) {
      return customDateRange;
    }
    return getDefaultDateRangeForYear(selectedYear);
  }

  /// Satış faturalarını tarih aralığına göre filtreler.
  /// 
  /// Yalnızca tamamlanmış (completed) faturaları dahil eder.
  static List<SalesInvoice> filterSalesInvoices({
    required List<SalesInvoice> invoices,
    required DateTimeRange dateRange,
  }) {
    return invoices
        .where((invoice) =>
            invoice.status == InvoiceStatus.completed &&
            isInDateRange(invoice.invoiceDate, dateRange))
        .toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  }

  /// Filtrelenmiş faturalardan son N tanesini formatlanmış data olarak döndürür.
  static List<Map<String, dynamic>> getRecentInvoicesData({
    required List<SalesInvoice> invoices,
    required DateTimeRange dateRange,
    int limit = 5,
  }) {
    final filtered = filterSalesInvoices(invoices: invoices, dateRange: dateRange);
    return filtered.take(limit).map((i) => {
      'invoiceNumber': i.invoiceNumber,
      'customerName': i.customerName ?? 'غير معروف',
      'totalAmount': i.totalAmount,
      'date': i.invoiceDate,
      'status': i.paymentStatus.name,
    }).toList();
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
