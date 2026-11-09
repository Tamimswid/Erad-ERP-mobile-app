import 'package:erad/core/network/network_info.dart';
import 'package:erad/core/theme/shadcn_theme.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/cities/data/datasource/city_remote_datasource.dart';
import 'package:erad/features/cities/data/models/city.dart';
import 'package:erad/features/cities/data/repositories/city_repository.dart';
import 'package:erad/features/invoices/data/models/invoice_list_filter.dart';
import 'package:erad/features/invoices/presentation/widgets/invoice_filter_sheet.dart';
import 'package:erad/features/products/data/datasource/product_remote_datasource.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get connectionStream => const Stream.empty();
}

class _FakeProductRemoteDataSource implements ProductRemoteDataSource {
  final List<ProductModel> products;

  _FakeProductRemoteDataSource(this.products);

  @override
  Future<PagedResult<ProductModel>> getProductsPage({
    required int offset,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    return PagedResult(items: products, hasMore: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCityRemoteDataSource implements CityRemoteDataSource {
  @override
  Future<List<CityModel>> getCities() async => const [];
}

ProductModel _product({
  String id = 'product-1',
  String name = 'Çay Lipton',
  String measurement = '200',
  String unit = 'G',
}) {
  return ProductModel(
    id: id,
    userId: 'user-1',
    code: 'P-1',
    name: name,
    unit: unit,
    measurement: measurement,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required ProductModel product,
  required ValueChanged<InvoiceListFilter?> onResult,
}) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final productRepository = ProductRepository(
    _FakeProductRemoteDataSource([product]),
    _FakeNetworkInfo(),
  );
  final cityRepository = CityRepository(
    _FakeCityRemoteDataSource(),
    _FakeNetworkInfo(),
  );

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => sc.ShadcnLayer(
        theme: AppShadcnTheme.light,
        darkTheme: AppShadcnTheme.light,
        themeMode: sc.ThemeMode.light,
        scaling: const sc.AdaptiveScaling(1),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            type: MaterialType.transparency,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<InvoiceListFilter>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => InvoiceFilterSheet(
                          initialFilter: const InvoiceListFilter(),
                          productRepository: productRepository,
                          cityRepository: cityRepository,
                        ),
                      );
                  onResult(result);
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('seçilen ürün miktar ve ölçüsüyle birlikte döner', (
    tester,
  ) async {
    InvoiceListFilter? result;
    await _openSheet(
      tester,
      product: _product(),
      onResult: (value) => result = value,
    );

    await tester.enterText(find.byType(TextField), 'çay');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Çay Lipton'), findsOneWidget);
    expect(find.text('200 G'), findsOneWidget);

    await tester.tap(find.text('Çay Lipton'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.products, hasLength(1));
    expect(result!.products.single.id, 'product-1');
    expect(result!.products.single.name, 'Çay Lipton');
    expect(result!.products.single.measurementLabel, '200 G');
    expect(result!.activeCount, 1);
  });
}
