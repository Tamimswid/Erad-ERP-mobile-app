import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/invoices/data/models/invoice_list_filter.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/repositories/invoice_repository.dart';
import 'package:erad/features/invoices/presentation/bloc/invoice_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  List<String> lastSalesProductIds = const [];
  List<String> lastPurchaseProductIds = const [];
  DateTime? lastDateFrom;
  DateTime? lastDateTo;

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
    lastDateFrom = dateFrom;
    lastDateTo = dateTo;
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
    lastPurchaseProductIds = productIds;
    return const Right(PagedResult(items: [], hasMore: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('uygulanan ürün filtresi state ve sorguya yansır', () async {
    final repository = _FakeInvoiceRepository();
    final cubit = InvoiceCubit(repository, DataChangeNotifier());
    await Future<void>.delayed(Duration.zero);

    const filter = InvoiceListFilter(
      products: [
        InvoiceProductSelection(id: 'product-1', name: 'Çay Lipton'),
      ],
    );
    cubit.applyListFilter(filter);
    await Future<void>.delayed(Duration.zero);

    expect(repository.lastSalesProductIds, ['product-1']);
    expect(cubit.state, isA<InvoiceFiltered>());
    final state = cubit.state as InvoiceFiltered;
    expect(state.filter, filter);
    expect(state.filter.activeCount, 1);

    await cubit.close();
  });

  test('tarih filtresi sorguya ve state\'e yansır', () async {
    final repository = _FakeInvoiceRepository();
    final cubit = InvoiceCubit(repository, DataChangeNotifier());
    await Future<void>.delayed(Duration.zero);

    final filter = InvoiceListFilter(
      dateFrom: DateTime(2026, 1, 1),
      dateTo: DateTime(2026, 12, 31),
    );
    cubit.applyListFilter(filter);
    await Future<void>.delayed(Duration.zero);

    expect(repository.lastDateFrom, DateTime(2026, 1, 1));
    expect(repository.lastDateTo, DateTime(2026, 12, 31));
    expect((cubit.state as InvoiceFiltered).filter.activeCount, 1);

    await cubit.close();
  });
}
