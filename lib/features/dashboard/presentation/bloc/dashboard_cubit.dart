import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/purchase_invoice.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/data/models/product.dart';
import '../../../expenses/data/repositories/expense_repository.dart';
import '../../../expenses/data/models/expense.dart';
import '../../../withdrawals/data/repositories/withdrawal_repository.dart';
import '../../../withdrawals/data/models/withdrawal.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;
  final ExpenseRepository _expenseRepository;
  final WithdrawalRepository _withdrawalRepository;

  DashboardCubit({
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
    required ExpenseRepository expenseRepository,
    required WithdrawalRepository withdrawalRepository,
  })  : _invoiceRepository = invoiceRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        _expenseRepository = expenseRepository,
        _withdrawalRepository = withdrawalRepository,
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
      // Calculate date range
      final effectiveDateRange = isCustom && dateRange != null
          ? dateRange
          : DateTimeRange(
              start: DateTime(int.parse(year), 1, 1),
              end: DateTime(int.parse(year), 12, 31),
            );

      // Fetch all data concurrently for performance
      final results = await Future.wait([
        _invoiceRepository.getSalesInvoices(),
        _invoiceRepository.getPurchaseInvoices(),
        _expenseRepository.getExpenses(
          startDate: effectiveDateRange.start,
          endDate: effectiveDateRange.end,
        ),
        _withdrawalRepository.getWithdrawals(
          startDate: effectiveDateRange.start,
          endDate: effectiveDateRange.end,
        ),
        _customerRepository.getCustomers(),
        _productRepository.getProducts(),
      ]);

      // Extract data from results
      final salesInvoicesResult = results[0] as dynamic;
      final purchaseInvoicesResult = results[1] as dynamic;
      final expensesResult = results[2] as dynamic;
      final withdrawalsResult = results[3] as dynamic;
      final customersResult = results[4] as dynamic;
      final productsResult = results[5] as dynamic;

      // Handle sales invoices
      List<SalesInvoice> salesInvoices = [];
      salesInvoicesResult.fold(
        (failure) => null,
        (invoices) => salesInvoices = invoices,
      );

      // Handle purchase invoices
      List<PurchaseInvoice> purchaseInvoices = [];
      purchaseInvoicesResult.fold(
        (failure) => null,
        (invoices) => purchaseInvoices = invoices,
      );

      // Handle expenses
      List<Expense> expenses = [];
      expensesResult.fold(
        (failure) => null,
        (expenseList) => expenses = expenseList,
      );

      // Handle withdrawals
      List<Withdrawal> withdrawals = [];
      withdrawalsResult.fold(
        (failure) => null,
        (withdrawalList) => withdrawals = withdrawalList,
      );

      // Handle customers
      int totalCustomers = 0;
      customersResult.fold(
        (failure) => null,
        (customerList) => totalCustomers = customerList.length,
      );

      // Handle products
      List<ProductModel> products = [];
      productsResult.fold(
        (failure) => null,
        (productList) => products = productList,
      );

      // Calculate totals based on date range
      final filteredSales = salesInvoices.where((invoice) {
        return invoice.invoiceDate.isAfter(effectiveDateRange.start) &&
            invoice.invoiceDate.isBefore(effectiveDateRange.end.add(const Duration(days: 1)));
      });

      final filteredPurchases = purchaseInvoices.where((invoice) {
        return invoice.invoiceDate.isAfter(effectiveDateRange.start) &&
            invoice.invoiceDate.isBefore(effectiveDateRange.end.add(const Duration(days: 1)));
      });

      final totalSales = filteredSales.fold(0.0, (sum, i) => sum + i.totalAmount);
      final totalPurchases = filteredPurchases.fold(0.0, (sum, i) => sum + i.totalAmount);

      // Calculate expenses
      final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

      // Calculate withdrawals
      final totalWithdrawals = withdrawals.fold(0.0, (sum, w) => sum + w.amount);

      // Calculate profits
      final totalProfit = totalSales - totalPurchases;
      final netProfit = totalProfit - totalExpenses - totalWithdrawals;

      // Get product count and low stock
      final totalProducts = products.length;
      final lowStockProducts = products
          .where((p) => p.currentStock < p.minStock)
          .map((p) => {
                'name': '${p.name} (${p.measurement}${p.unit})',
                'stock': p.currentStock,
                'unit': '',
              })
          .take(7)
          .toList();

      // Get recent invoices
      final recentInvoices = filteredSales
          .toList()
          ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      final recentInvoicesData = recentInvoices.take(5).map((i) => {
            'invoiceNumber': i.invoiceNumber,
            'customerName': i.customerName ?? 'غير معروف',
            'totalAmount': i.totalAmount,
            'date': i.invoiceDate,
            'status': i.paymentStatus.name,
          }).toList();

      // Calculate monthly chart data
      final monthlyChartData = _calculateMonthlyChartData(
        salesInvoices,
        purchaseInvoices,
        expenses,
        withdrawals,
        effectiveDateRange,
      );

      // Calculate top products by sales quantity
      final topProductsBySales = _calculateTopProductsBySales(filteredSales.toList());

      // Calculate top products by purchases quantity (from purchase invoices)
      final topProductsByPurchases = _calculateTopProductsByPurchases(filteredPurchases.toList());

      emit(DashboardLoaded(
        totalSales: totalSales,
        totalPurchases: totalPurchases,
        totalExpenses: totalExpenses,
        totalWithdrawals: totalWithdrawals,
        totalProfit: totalProfit,
        netProfit: netProfit,
        totalCustomers: totalCustomers,
        totalProducts: totalProducts,
        monthlyChartData: monthlyChartData,
        lowStockProducts: lowStockProducts,
        recentInvoices: recentInvoicesData,
        topProductsBySales: topProductsBySales,
        topProductsByPurchases: topProductsByPurchases,
        selectedYear: year,
        customDateRange: dateRange,
        isCustomDateRange: isCustom,
      ));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard data: $e'));
    }
  }

  List<Map<String, dynamic>> _calculateTopProductsBySales(List<SalesInvoice> salesInvoices) {
    final Map<String, Map<String, dynamic>> productSales = {};

    for (final invoice in salesInvoices) {
      for (final item in invoice.items) {
        final productName = item.productName.isNotEmpty ? item.productName : (item.productId ?? 'Unknown');
        final unit = item.unit.isNotEmpty ? item.unit : 'pcs';
        final quantity = item.quantity;

        if (productSales.containsKey(productName)) {
          productSales[productName]!['quantity'] = (productSales[productName]!['quantity'] as num) + quantity;
        } else {
          productSales[productName] = {
            'name': productName,
            'quantity': quantity,
            'unit': unit,
          };
        }
      }
    }

    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => (b['quantity'] as num).compareTo(a['quantity'] as num));

    return sortedProducts.take(1).toList();
  }

  List<Map<String, dynamic>> _calculateTopProductsByPurchases(List<PurchaseInvoice> purchaseInvoices) {
    final Map<String, Map<String, dynamic>> productPurchases = {};

    for (final invoice in purchaseInvoices) {
      for (final item in invoice.items) {
        final productName = item.productName.isNotEmpty ? item.productName : (item.productId ?? 'Unknown');
        final unit = item.unit.isNotEmpty ? item.unit : 'pcs';
        final quantity = item.quantity;

        if (productPurchases.containsKey(productName)) {
          productPurchases[productName]!['quantity'] = (productPurchases[productName]!['quantity'] as num) + quantity;
        } else {
          productPurchases[productName] = {
            'name': productName,
            'quantity': quantity,
            'unit': unit,
          };
        }
      }
    }

    final sortedProducts = productPurchases.values.toList()
      ..sort((a, b) => (b['quantity'] as num).compareTo(a['quantity'] as num));

    return sortedProducts;
  }

  List<Map<String, dynamic>> _calculateMonthlyChartData(
    List<SalesInvoice> salesInvoices,
    List<PurchaseInvoice> purchaseInvoices,
    List<Expense> expenses,
    List<Withdrawal> withdrawals,
    DateTimeRange dateRange,
  ) {
    final year = dateRange.start.year;

    final monthlyData = List.generate(12, (index) {
      final month = index + 1;
      final monthName = _getArabicMonthName(month);

      final monthSales = salesInvoices
          .where((i) => i.invoiceDate.month == month && i.invoiceDate.year == year)
          .fold(0.0, (sum, i) => sum + i.totalAmount);

      final monthPurchases = purchaseInvoices
          .where((i) => i.invoiceDate.month == month && i.invoiceDate.year == year)
          .fold(0.0, (sum, i) => sum + i.totalAmount);

      final monthExpenses = expenses
          .where((e) => e.expenseDate.month == month && e.expenseDate.year == year)
          .fold(0.0, (sum, e) => sum + e.amount);

      final monthWithdrawals = withdrawals
          .where((w) => w.withdrawalDate.month == month && w.withdrawalDate.year == year)
          .fold(0.0, (sum, w) => sum + w.amount);

      final profit = monthSales - monthPurchases;

      return {
        'month': monthName,
        'monthIndex': month,
        'sales': monthSales,
        'purchases': monthPurchases,
        'expenses': monthExpenses,
        'withdrawals': monthWithdrawals,
        'profit': profit,
      };
    });

    return monthlyData;
  }

  String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  void setYear(String year) {
    if (state is DashboardLoaded) {
      loadDashboardData(year, null, false);
    }
  }

  void setCustomDateRange(DateTimeRange dateRange) {
    if (state is DashboardLoaded) {
      loadDashboardData(
        DateTime.now().year.toString(),
        dateRange,
        true,
      );
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
