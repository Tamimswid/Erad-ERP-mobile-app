import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/invoice_list_filter.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:flutter_test/flutter_test.dart';

SalesInvoice _salesInvoice({
  PaymentStatus paymentStatus = PaymentStatus.cash,
  String? customerCityId,
  String? customerCityName,
  List<String?> productIds = const [],
}) {
  return SalesInvoice(
    id: 'sale-1',
    userId: 'user-1',
    invoiceNumber: 'S-1',
    invoiceDate: DateTime(2026, 1, 1),
    subtotal: 100,
    totalAmount: 100,
    status: InvoiceStatus.completed,
    paymentStatus: paymentStatus,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerCityId: customerCityId,
    customerCityName: customerCityName,
    items: productIds
        .map((productId) => InvoiceItem(productId: productId))
        .toList(),
  );
}

PurchaseInvoice _purchaseInvoice({
  PaymentStatus paymentStatus = PaymentStatus.cash,
  String? supplierCityId,
  String? supplierCityName,
  List<String?> productIds = const [],
}) {
  return PurchaseInvoice(
    id: 'purchase-1',
    userId: 'user-1',
    invoiceNumber: 'P-1',
    invoiceDate: DateTime(2026, 1, 1),
    subtotal: 100,
    totalAmount: 100,
    status: InvoiceStatus.completed,
    paymentStatus: paymentStatus,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    supplierCityId: supplierCityId,
    supplierCityName: supplierCityName,
    items: productIds
        .map((productId) => InvoiceItem(productId: productId))
        .toList(),
  );
}

const _productA = InvoiceProductSelection(id: 'product-a', name: 'A');
const _productB = InvoiceProductSelection(id: 'product-b', name: 'B');

void main() {
  group('InvoiceListFilter.activeCount', () {
    test('boş filtre sıfır döner', () {
      const filter = InvoiceListFilter();

      expect(filter.isEmpty, isTrue);
      expect(filter.activeCount, 0);
    });

    test('her aktif grup sayıya eklenir', () {
      final filter = InvoiceListFilter(
        paymentStatus: 'debt',
        cityId: 'city-1',
        cityName: 'İstanbul',
        products: const [_productA, _productB],
      );

      expect(filter.activeCount, 3);
      expect(filter.isEmpty, isFalse);
    });

    test('yalnızca ürün seçimi bir grup sayılır', () {
      const filter = InvoiceListFilter(products: [_productA]);

      expect(filter.activeCount, 1);
    });

    test('tarih aralığı bir grup sayılır', () {
      final filter = InvoiceListFilter(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31),
      );

      expect(filter.hasDateRange, isTrue);
      expect(filter.activeCount, 1);
    });
  });

  group('InvoiceListFilter.matchesSales', () {
    test('filtre yokken tüm faturalar eşleşir', () {
      const filter = InvoiceListFilter();

      expect(filter.matchesSales(_salesInvoice()), isTrue);
    });

    test('ödeme durumu filtreyi uygular', () {
      const filter = InvoiceListFilter(paymentStatus: 'debt');

      expect(
        filter.matchesSales(_salesInvoice(paymentStatus: PaymentStatus.debt)),
        isTrue,
      );
      expect(
        filter.matchesSales(_salesInvoice(paymentStatus: PaymentStatus.cash)),
        isFalse,
      );
    });

    test('şehir kimliği ile eşleştirir', () {
      const filter = InvoiceListFilter(cityId: 'city-1', cityName: 'İstanbul');

      expect(
        filter.matchesSales(_salesInvoice(customerCityId: 'city-1')),
        isTrue,
      );
      expect(
        filter.matchesSales(_salesInvoice(customerCityId: 'city-2')),
        isFalse,
      );
    });

    test('eski kayıtlarda şehir adına düşer', () {
      const filter = InvoiceListFilter(cityId: 'city-1', cityName: 'İstanbul');

      expect(
        filter.matchesSales(_salesInvoice(customerCityName: 'İstanbul')),
        isTrue,
      );
      expect(
        filter.matchesSales(_salesInvoice(customerCityName: 'Ankara')),
        isFalse,
      );
    });

    test('seçilen ürünlerden herhangi biri yeterlidir (OR)', () {
      const filter = InvoiceListFilter(products: [_productA, _productB]);

      expect(
        filter.matchesSales(_salesInvoice(productIds: ['product-b'])),
        isTrue,
      );
      expect(
        filter.matchesSales(_salesInvoice(productIds: ['product-c'])),
        isFalse,
      );
      expect(filter.matchesSales(_salesInvoice()), isFalse);
    });

    test('boş ürün kimlikleri eşleşmez', () {
      const filter = InvoiceListFilter(products: [_productA]);

      expect(filter.matchesSales(_salesInvoice(productIds: [null])), isFalse);
    });

    test('tüm gruplar birlikte uygulanır', () {
      const filter = InvoiceListFilter(
        paymentStatus: 'cash',
        cityId: 'city-1',
        products: [_productA],
      );

      expect(
        filter.matchesSales(
          _salesInvoice(
            paymentStatus: PaymentStatus.cash,
            customerCityId: 'city-1',
            productIds: ['product-a'],
          ),
        ),
        isTrue,
      );
      expect(
        filter.matchesSales(
          _salesInvoice(
            paymentStatus: PaymentStatus.cash,
            customerCityId: 'city-1',
            productIds: ['product-b'],
          ),
        ),
        isFalse,
      );
    });
  });

  group('InvoiceListFilter.matchesPurchase', () {
    test('tedarikçi şehri ile eşleştirir', () {
      const filter = InvoiceListFilter(cityId: 'city-1');

      expect(
        filter.matchesPurchase(_purchaseInvoice(supplierCityId: 'city-1')),
        isTrue,
      );
      expect(
        filter.matchesPurchase(_purchaseInvoice(supplierCityId: 'city-2')),
        isFalse,
      );
    });

    test('eski kayıtlarda şehir adına düşer', () {
      const filter = InvoiceListFilter(cityId: 'city-1', cityName: 'İzmir');

      expect(
        filter.matchesPurchase(_purchaseInvoice(supplierCityName: 'İzmir')),
        isTrue,
      );
      expect(
        filter.matchesPurchase(_purchaseInvoice(supplierCityName: 'Bursa')),
        isFalse,
      );
    });

    test('ödeme durumu ve ürün filtreleri birlikte çalışır', () {
      const filter = InvoiceListFilter(
        paymentStatus: 'debt',
        products: [_productA, _productB],
      );

      expect(
        filter.matchesPurchase(
          _purchaseInvoice(
            paymentStatus: PaymentStatus.debt,
            productIds: ['product-b'],
          ),
        ),
        isTrue,
      );
      expect(
        filter.matchesPurchase(
          _purchaseInvoice(
            paymentStatus: PaymentStatus.cash,
            productIds: ['product-b'],
          ),
        ),
        isFalse,
      );
    });
  });

  group('InvoiceProductSelection', () {
    test('JSON dönüşümü alanları korur', () {
      const selection = InvoiceProductSelection(
        id: 'id-1',
        name: 'Ürün',
        measurement: '200',
        unit: 'G',
      );

      final json = selection.toJson();
      final restored = InvoiceProductSelection.fromJson(json);

      expect(restored, selection);
    });

    test('eksik JSON alanları boş değere düşer', () {
      final restored = InvoiceProductSelection.fromJson(const {});

      expect(restored.id, isEmpty);
      expect(restored.name, isEmpty);
      expect(restored.measurement, isEmpty);
      expect(restored.unit, isEmpty);
    });

    test('miktar ve ölçü etiketini birleştirir', () {
      const selection = InvoiceProductSelection(
        id: 'id-1',
        name: 'Çay Lipton',
        measurement: '200',
        unit: 'G',
      );

      expect(selection.measurementLabel, '200 G');
      expect(selection.displayName, 'Çay Lipton · 200 G');
    });

    test('ölçü yoksa yalnızca ürün adı gösterilir', () {
      const selection = InvoiceProductSelection(id: 'id-1', name: 'Çay');

      expect(selection.measurementLabel, isEmpty);
      expect(selection.displayName, 'Çay');
    });
  });
}
