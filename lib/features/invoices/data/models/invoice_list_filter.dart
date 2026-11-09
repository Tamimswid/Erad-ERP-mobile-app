import 'package:equatable/equatable.dart';

import 'purchase_invoice.dart';
import 'sales_invoice.dart';

/// منتج تم اختياره في فلتر الفواتير.
///
/// يُحفظ الاسم مع المعرف لأن الورقة تعرض الاختيارات دون إعادة جلب المنتجات.
class InvoiceProductSelection extends Equatable {
  final String id;
  final String name;
  final String measurement;
  final String unit;

  const InvoiceProductSelection({
    required this.id,
    required this.name,
    this.measurement = '',
    this.unit = '',
  });

  factory InvoiceProductSelection.fromJson(Map<String, dynamic> json) {
    return InvoiceProductSelection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      measurement: json['measurement'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'measurement': measurement,
    'unit': unit,
  };

  /// Ölçü ve birimi tek etikette birleştirir (örn. "200 G").
  String get measurementLabel {
    final parts = [
      measurement,
      unit,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  /// Seçili chip'lerde ürün adıyla birlikte miktar/ölçü gösterir.
  String get displayName {
    final label = measurementLabel;
    return label.isEmpty ? name : '$name · $label';
  }

  @override
  List<Object?> get props => [id, name, measurement, unit];
}

/// حالة فلتر قائمة الفواتير.
///
/// المنتجات تعمل بمنطق OR: تكفي مطابقة أي منتج مختار داخل بنود الفاتورة.
class InvoiceListFilter extends Equatable {
  static const String allPaymentStatus = 'all';

  final String paymentStatus;
  final String? cityId;
  final String? cityName;
  final List<InvoiceProductSelection> products;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const InvoiceListFilter({
    this.paymentStatus = allPaymentStatus,
    this.cityId,
    this.cityName,
    this.products = const [],
    this.dateFrom,
    this.dateTo,
  });

  bool get hasPaymentStatus => paymentStatus != allPaymentStatus;

  bool get hasCity => cityId != null;

  bool get hasProducts => products.isNotEmpty;

  bool get hasDateRange => dateFrom != null || dateTo != null;

  bool get isEmpty => activeCount == 0;

  /// عدد مجموعات الفلترة النشطة، يُستخدم في شارة زر الفلتر.
  int get activeCount {
    var count = 0;
    if (hasPaymentStatus) count++;
    if (hasCity) count++;
    if (hasProducts) count++;
    if (hasDateRange) count++;
    return count;
  }

  Set<String> get productIds => products.map((product) => product.id).toSet();

  /// فلترة محلية للبيانات المخزنة عند انقطاع الاتصال.
  bool matchesSales(SalesInvoice invoice) {
    if (hasPaymentStatus && invoice.paymentStatus.name != paymentStatus) {
      return false;
    }
    if (!_matchesCustomerCity(invoice)) return false;
    if (!_matchesProducts(invoice.items.map((item) => item.productId))) {
      return false;
    }
    return true;
  }

  /// فلترة محلية للبيانات المخزنة عند انقطاع الاتصال.
  bool matchesPurchase(PurchaseInvoice invoice) {
    if (hasPaymentStatus && invoice.paymentStatus.name != paymentStatus) {
      return false;
    }
    if (!_matchesSupplierCity(invoice)) return false;
    if (!_matchesProducts(invoice.items.map((item) => item.productId))) {
      return false;
    }
    return true;
  }

  bool _matchesCustomerCity(SalesInvoice invoice) {
    if (!hasCity) return true;
    if (invoice.customerCityId != null) {
      return invoice.customerCityId == cityId;
    }
    // توافق مع الفواتير المخزنة قبل إضافة city_id.
    return cityName != null && invoice.customerCityName == cityName;
  }

  bool _matchesSupplierCity(PurchaseInvoice invoice) {
    if (!hasCity) return true;
    if (invoice.supplierCityId != null) {
      return invoice.supplierCityId == cityId;
    }
    return cityName != null && invoice.supplierCityName == cityName;
  }

  /// يكفي تطابق أي منتج مختار (OR).
  bool _matchesProducts(Iterable<String?> invoiceProductIds) {
    if (!hasProducts) return true;
    final selected = productIds;
    return invoiceProductIds.any(
      (productId) => productId != null && selected.contains(productId),
    );
  }

  @override
  List<Object?> get props => [
    paymentStatus,
    cityId,
    cityName,
    products,
    dateFrom,
    dateTo,
  ];
}
