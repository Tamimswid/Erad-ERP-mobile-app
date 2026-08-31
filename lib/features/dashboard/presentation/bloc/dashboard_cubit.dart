import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../data/models/dashboard_financials.dart';
import '../../data/models/dashboard_product_stock.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/helpers/dashboard_filter_helper.dart';

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
    loadDashboardData(year: currentYear);
  }

  /// Dashboard verilerini yükler.
  /// 
  /// [year] veya [customDateRange] belirtilebilir.
  /// Custom date range varsa onu kullanır, yoksa yıl için varsayılan aralık oluşturur.
  Future<void> loadDashboardData({
    required String year,
    DateTimeRange? customDateRange,
  }) async {
    emit(const DashboardLoading());

    try {
      // Aktif tarih aralığını belirle
      final dateRange = DashboardFilterHelper.getActiveDateRange(
        selectedYear: year,
        customDateRange: customDateRange,
      );

      // Tarihleri formatla (YYYY-MM-DD)
      final startDate = DashboardFilterHelper.formatDateForApi(dateRange.start);
      final endDate = DashboardFilterHelper.formatDateForApi(dateRange.end);

      // Paralel olarak tüm verileri çek
      final results = await Future.wait([
        _dashboardRepository.getFinancials(startDate: startDate, endDate: endDate),
        _dashboardRepository.getProductStock(),
        _customerRepository.getCustomers(),
        _productRepository.getProducts(),
        _invoiceRepository.getSalesInvoices(),
      ]);

      // Finansal veriler (tarih filtresi backend'de uygulandı)
      DashboardFinancialsModel financials = const DashboardFinancialsModel(userId: '');
      final financialsResult = results[0] as Either<Failure, DashboardFinancialsModel>;
      financialsResult.fold(
        (failure) => null,
        (data) => financials = data,
      );

      // Ürün stokları
      List<DashboardProductStockModel> productStock = [];
      final stockResult = results[1] as Either<Failure, List<DashboardProductStockModel>>;
      stockResult.fold(
        (failure) => null,
        (data) => productStock = data,
      );

      // Müşteri sayısı
      int totalCustomers = 0;
      final customersResult = results[2] as Either<Failure, List>;
      customersResult.fold(
        (failure) => null,
        (data) => totalCustomers = data.length,
      );

      // Ürün sayısı
      int totalProducts = 0;
      final productsResult = results[3] as Either<Failure, List>;
      productsResult.fold(
        (failure) => null,
        (data) => totalProducts = data.length,
      );

      // Satış faturaları (yerel filtreleme ile tarih aralığını uygula)
      List<SalesInvoice> salesInvoices = [];
      final invoicesResult = results[4] as Either<Failure, List<SalesInvoice>>;
      invoicesResult.fold(
        (failure) => null,
        (data) => salesInvoices = data,
      );

      // Son faturaları filtrele ve formatla
      final recentInvoices = DashboardFilterHelper.getRecentInvoicesData(
        invoices: salesInvoices,
        dateRange: dateRange,
        limit: 5,
      );

      emit(DashboardLoaded(
        financials: financials,
        productStock: productStock,
        totalCustomers: totalCustomers,
        totalProducts: totalProducts,
        recentInvoices: recentInvoices,
        selectedYear: year,
        customDateRange: customDateRange,
        isCustomDateRange: customDateRange != null,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard data: $e'));
    }
  }

  /// Yıl değişikliğinde verileri yeniden yükler.
  void setYear(String year) {
    loadDashboardData(year: year);
  }

  /// Özel tarih aralığında verileri yeniden yükler.
  void setCustomDateRange(DateTimeRange dateRange) {
    loadDashboardData(
      year: DateTime.now().year.toString(),
      customDateRange: dateRange,
    );
  }

  /// Filtreyi temizler ve yıl bazlı varsayılan aralığa döner.
  void clearCustomDateRange() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(year: currentState.selectedYear);
    }
  }

  /// Veriyi yeniler.
  void refreshData() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      loadDashboardData(
        year: currentState.selectedYear,
        customDateRange: currentState.customDateRange,
      );
    }
  }

  /// Kullanılabilir yılları döndürür.
  List<String> getAvailableYears() => DashboardFilterHelper.getAvailableYears();

  /// Tarih aralığının etiketini döndürür.
  String getDateRangeLabel() {
    if (state is! DashboardLoaded) return '';
    final loaded = state as DashboardLoaded;
    return DashboardFilterHelper.getDateRangeLabel(
      selectedYear: loaded.selectedYear,
      customDateRange: loaded.customDateRange,
    );
  }
}
