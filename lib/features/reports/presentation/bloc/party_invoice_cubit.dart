import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/report_repository.dart';
import '../../../invoices/data/models/sales_invoice.dart';
import '../../../invoices/data/models/purchase_invoice.dart';

part 'party_invoice_state.dart';

class PartyInvoiceCubit extends Cubit<PartyInvoiceState> {
  final ReportRepository _repository;

  List<SalesInvoice> _allSales = [];
  List<PurchaseInvoice> _allPurchase = [];

  String? _selectedYear;
  DateTimeRange? _customDateRange;
  bool _isCustomDateRange = false;

  PartyInvoiceCubit(this._repository) : super(const PartyInvoiceInitial());

  String? get selectedYear => _selectedYear;
  DateTimeRange? get customDateRange => _customDateRange;
  bool get isCustomDateRange => _isCustomDateRange;

  List<String> get availableYears {
    final years = <String>{};
    for (final inv in _allSales) {
      years.add(inv.invoiceDate.year.toString());
    }
    for (final inv in _allPurchase) {
      years.add(inv.invoiceDate.year.toString());
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted.isEmpty ? [DateTime.now().year.toString()] : sorted;
  }

  Future<void> loadInvoices(String partyId, bool isSupplier) async {
    emit(const PartyInvoiceLoading());
    try {
      if (isSupplier) {
        final result = await _repository.getPurchaseInvoicesBySupplier(partyId);
        result.fold(
          (failure) => emit(PartyInvoiceError(failure.message)),
          (invoices) {
            _allPurchase = invoices;
            _allSales = [];
            _applyFilter();
          },
        );
      } else {
        final result = await _repository.getSalesInvoicesByCustomer(partyId);
        result.fold(
          (failure) => emit(PartyInvoiceError(failure.message)),
          (invoices) {
            _allSales = invoices;
            _allPurchase = [];
            _applyFilter();
          },
        );
      }
    } catch (e) {
      emit(PartyInvoiceError(e.toString()));
    }
  }

  void setYear(String year) {
    _selectedYear = year;
    _isCustomDateRange = false;
    _customDateRange = null;
    _applyFilter();
  }

  void setCustomDateRange(DateTimeRange range) {
    _customDateRange = range;
    _isCustomDateRange = true;
    _selectedYear = null;
    _applyFilter();
  }

  void clearFilter() {
    _selectedYear = null;
    _customDateRange = null;
    _isCustomDateRange = false;
    _applyFilter();
  }

  void _applyFilter() {
    List<dynamic> filtered = [];

    if (_allSales.isNotEmpty) {
      filtered.addAll(_allSales);
    } else if (_allPurchase.isNotEmpty) {
      filtered.addAll(_allPurchase);
    }

    if (_isCustomDateRange && _customDateRange != null) {
      filtered = filtered.where((inv) {
        final date = _getInvoiceDate(inv);
        return !date.isBefore(_customDateRange!.start) &&
            !date.isAfter(_customDateRange!.end);
      }).toList();
    } else if (_selectedYear != null) {
      filtered = filtered
          .where((inv) => _getInvoiceDate(inv).year.toString() == _selectedYear)
          .toList();
    }

    emit(PartyInvoiceLoaded(
      invoices: filtered,
      totalCount: filtered.length,
    ));
  }

  DateTime _getInvoiceDate(dynamic inv) {
    if (inv is SalesInvoice) return inv.invoiceDate;
    if (inv is PurchaseInvoice) return inv.invoiceDate;
    return DateTime.now();
  }
}
