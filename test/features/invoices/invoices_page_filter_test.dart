import 'package:dartz/dartz.dart';
import 'package:erad/core/di/services_locator.dart' as sl;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/core/theme/shadcn_theme.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/cities/data/datasource/city_remote_datasource.dart';
import 'package:erad/features/cities/data/models/city.dart';
import 'package:erad/features/cities/data/repositories/city_repository.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/repositories/invoice_repository.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:erad/features/invoices/presentation/pages/invoices_page.dart';
import 'package:erad/features/invoices/presentation/widgets/invoice_filter_button.dart';
import 'package:erad/features/products/data/datasource/product_remote_datasource.dart';
import 'package:erad/features/products/data/models/product.dart';
import 'package:erad/features/products/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get connectionStream => const Stream.empty();
}

class _FakeProductRemoteDataSource implements ProductRemoteDataSource {
  @override
  Future<PagedResult<ProductModel>> getProductsPage({
    required int offset,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    return PagedResult(
      items: [
        ProductModel(
          id: 'product-1',
          userId: 'user-1',
          code: 'P-1',
          name: 'Çay Lipton',
          unit: 'G',
          measurement: '200',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ],
      hasMore: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCityRemoteDataSource implements CityRemoteDataSource {
  @override
  Future<List<CityModel>> getCities() async => const [];
}

class _FakeInvoiceRepository implements InvoiceRepository {
  List<String> lastSalesProductIds = const [];

  @override
  Future<Either<Failure, PagedResult<SalesInvoice>>> getSalesInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    String? cityId,
    String? cityName,
    List<String> productIds = const [],
  }) async {
    lastSalesProductIds = productIds;
    return const Right(PagedResult(items: [], hasMore: false));
  }

  @override
  Future<Either<Failure, PagedResult<PurchaseInvoice>>>
  getPurchaseInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    String? cityId,
    String? cityName,
    List<String> productIds = const [],
  }) async {
    return const Right(PagedResult(items: [], hasMore: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder _productSearchField() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'ابحث عن منتج بالاسم...',
  );
}

/// Mimics the old DashboardPage behaviour where the keyboard swapped the
/// subtree, disposing the invoices page while the sheet was still open.
class _SwappingHost extends StatelessWidget {
  final Widget child;

  const _SwappingHost({required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 100;
    return keyboardVisible ? Column(children: [Expanded(child: child)]) : child;
  }
}

Widget _app(Widget home) {
  return MaterialApp(
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
    home: home,
  );
}

void main() {
  final repository = _FakeInvoiceRepository();
  late InvoiceCubit cubit;

  setUp(() async {
    await sl.sl.reset();
    sl.sl.registerSingleton<DataChangeNotifier>(DataChangeNotifier());
    sl.sl.registerSingleton<ProductRepository>(
      ProductRepository(_FakeProductRemoteDataSource(), _FakeNetworkInfo()),
    );
    sl.sl.registerSingleton<CityRepository>(
      CityRepository(_FakeCityRemoteDataSource(), _FakeNetworkInfo()),
    );
    repository.lastSalesProductIds = const [];
    cubit = InvoiceCubit(repository, sl.sl<DataChangeNotifier>());
  });

  tearDown(() async {
    await cubit.close();
    await sl.sl.reset();
  });

  testWidgets(
    'ürün filtresi uygulanınca listeye gider ve rozet sayısı görünür',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(BlocProvider.value(value: cubit, child: const InvoicesPage())),
      );
      await tester.pumpAndSettle();

      expect(repository.lastSalesProductIds, isEmpty);
      expect(
        tester
            .widget<InvoiceFilterButton>(find.byType(InvoiceFilterButton))
            .activeCount,
        0,
      );
      expect(
        find.descendant(
          of: find.byType(InvoiceFilterButton),
          matching: find.text('1'),
        ),
        findsNothing,
      );

      await tester.tap(find.byType(InvoiceFilterButton));
      await tester.pumpAndSettle();

      await tester.enterText(_productSearchField(), 'çay');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Çay Lipton'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تطبيق'));
      await tester.pumpAndSettle();

      expect(repository.lastSalesProductIds, ['product-1']);
      expect(
        tester
            .widget<InvoiceFilterButton>(find.byType(InvoiceFilterButton))
            .activeCount,
        1,
      );
      expect(
        find.descendant(
          of: find.byType(InvoiceFilterButton),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('klavye açılırken sayfa yeniden kurulsa da filtre uygulanır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        BlocProvider.value(
          value: cubit,
          child: const _SwappingHost(child: InvoicesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InvoiceFilterButton));
    await tester.pumpAndSettle();

    await tester.enterText(_productSearchField(), 'çay');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Çay Lipton'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();

    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(repository.lastSalesProductIds, ['product-1']);
    expect(
      tester
          .widget<InvoiceFilterButton>(find.byType(InvoiceFilterButton))
          .activeCount,
      1,
    );
  });
}
