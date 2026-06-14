import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/invoice_status.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../data/models/dashboard_financials.dart';
import '../../data/models/dashboard_product_stock.dart';
import '../../data/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _dashboardRepository;
  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;

  DashboardCubit({
    required DashboardRepository dashboardRepository,
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
  })  : _dashboardRepository = dashboardRepository,
        _invoiceRepository = invoiceRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        super(const DashboardInitial()) {
    _initialize();
  }

  void _initialize() {
    final currentYear = DateTime.now().year.toString();
    loadDashboardData(currentYear, null, false);
  }

  Future<void> loadDashboardData(String year, DateTimeRange? dateRange, bool isCustom) async {
    emit(const DashboardLoading());

    try {
      final effectiveDateRange = isCustom && dateRange != null
          ? dateRange
          : DateTimeRange(
              start: DateTime(int.parse(year), 1, 1),
              end: DateTime(int.parse(year), 12, 31),
            );

      final results = await Future.wait([
        _dashboardRepository.getFinancials(),
        _dashboardRepository.getProductStock(),
        _customerRepository.getCustomers(),
        _productRepository.getProducts(),
        _invoiceRepository.getSalesInvoices(),
      ]);

      DashboardFinancialsModel financials = const DashboardFinancialsModel(userId: '');
      final financialsResult = results[0] as Either<Failure, DashboardFinancialsModel>;
      financialsResult.fold((failure) => null, (data) => financials = data);

      List<DashboardProductStockModel> productStock = [];
      final stockResult = results[1] as Either<Failure, List<DashboardProductStockModel>>;
      stockResult.fold((failure) => null, (data) => productStock = data);

      int totalCustomers = 0;
      final customersResult = results[2] as Either<Failure, List>;
      customersResult.fold((failure) => null, (data) => totalCustomers = data.length);

      int totalProducts = 0;
      final productsResult = results[3] as Either<Failure, List>;
      productsResult.fold((failure) => null, (data) => totalProducts = data.length);

      List<SalesInvoice> salesInvoices = [];
      final invoicesResult = results[4] as Either<Failure, List<SalesInvoice>>;
      invoicesResult.fold((failure) => null, (data) => salesInvoices = data);

      final recentInvoices = salesInvoices
          .where((i) => i.status == InvoiceStatus.completed
              && i.invoiceDate.isAfter(effectiveDateRange.start)
              && i.invoiceDate.isBefore(effectiveDateRange.end.add(const Duration(days: 1))))
          .toList()
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      final recentInvoicesData = recentInvoices.take(5).map((i) => {
            'invoiceNumber': i.invoiceNumber,
            'customerName': i.customerName ?? 'غير معروف',
            'totalAmount': i.totalAmount,
            'date': i.invoiceDate,
            'status': i.paymentStatus.name,
          }).toList();

      emit(DashboardLoaded(
        financials: financials,
        productStock: productStock,
        totalCustomers: totalCustomers,
        totalProducts: totalProducts,
        recentInvoices: recentInvoicesData,
        selectedYear: year,
        customDateRange: dateRange,
        isCustomDateRange: isCustom,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard data: $e'));
    }
  }

  void setYear(String year) {
    if (state is DashboardLoaded) {
      loadDashboardData(year, null, false);
    }
  }

  void setCustomDateRange(DateTimeRange dateRange) {
    if (state is DashboardLoaded) {
      loadDashboardData(DateTime.now().year.toString(), dateRange, true);
    }
  }

  void clearCustomDateRange() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(currentState.selectedYear, null, false);
    }
  }

  void refreshData() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(
        currentState.selectedYear,
        currentState.customDateRange,
        currentState.isCustomDateRange,
      );
    }
  }

  List<String> getAvailableYears() {
    final currentYear = DateTime.now().year;
    return [
      currentYear.toString(),
      (currentYear - 1).toString(),
      (currentYear - 2).toString(),
    ];
  }
}
