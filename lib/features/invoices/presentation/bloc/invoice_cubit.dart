import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/data/repositories/invoice_repository.dart';
import 'package:equatable/equatable.dart';

part 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  static const int pageSize = 10;

  final InvoiceRepository _repository;
  final DataChangeNotifier _dataChanges;
  final List<dynamic> _pagedInvoices = [];
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  Timer? _searchDebounce;

  // New filtering state
  String _selectedType = 'sale';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Invoice creation state
  String _invoiceType = 'sale';
  String? _selectedCustomerId;
  String? _selectedSupplierId;
  List<InvoiceItem> _invoiceItems = [];
  double _discountAmount = 0.0;
  double _paidAmount = 0.0;
  String _notes = '';
  String _reference = '';
  String _project = '';
  String _paymentMethod = '';
  String? _paymentType; // 'debt' or 'cash' - no default selection
  String _status = 'completed';
  int _formUpdateRevision = 0;

  // Getters for accessing filter state
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // Getters for invoice creation state
  String get invoiceType => _invoiceType;
  String? get selectedCustomerId => _selectedCustomerId;
  String? get selectedSupplierId => _selectedSupplierId;
  List<InvoiceItem> get invoiceItems => _invoiceItems;
  double get discountAmount => _discountAmount;
  double get paidAmount => _paidAmount;
  String get notes => _notes;
  String get reference => _reference;
  String get project => _project;
  String get paymentMethod => _paymentMethod;
  String? get paymentType => _paymentType;
  String get status => _status;

  InvoiceCubit(this._repository, this._dataChanges)
    : super(const InvoiceInitial()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage({bool showLoading = true}) async {
    final requestId = ++_requestId;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    if (showLoading && !isClosed) emit(const InvoiceLoading());

    if (_selectedType == 'purchase') {
      final result = await _repository.getPurchaseInvoicesPage(
        offset: 0,
        limit: pageSize,
        status: _selectedStatus,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _searchQuery,
      );
      if (isClosed || requestId != _requestId) return;
      result.fold(
        (failure) {
          _offset = previousOffset;
          _hasMore = previousHasMore;
          emit(InvoiceError(failure.message));
          if (_hasLoaded) _emitFiltered();
        },
        (page) {
          _pagedInvoices
            ..clear()
            ..addAll(page.items);
          _offset = page.items.length;
          _hasMore = page.hasMore;
          _hasLoaded = true;
          _emitFiltered();
        },
      );
      return;
    }

    final result = await _repository.getSalesInvoicesPage(
      offset: 0,
      limit: pageSize,
      status: _selectedStatus,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      search: _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(InvoiceError(failure.message));
        if (_hasLoaded) _emitFiltered();
      },
      (page) {
        _pagedInvoices
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _hasLoaded = true;
        _emitFiltered();
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _emitFiltered();

    final requestId = _requestId;
    final result = _selectedType == 'purchase'
        ? await _repository.getPurchaseInvoicesPage(
            offset: _offset,
            limit: pageSize,
            status: _selectedStatus,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            search: _searchQuery,
          )
        : await _repository.getSalesInvoicesPage(
            offset: _offset,
            limit: pageSize,
            status: _selectedStatus,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            search: _searchQuery,
          );

    if (isClosed || requestId != _requestId) return;
    _isLoadingMore = false;
    result.fold(
      (failure) {
        _hasMore = false;
        _emitFiltered();
      },
      (page) {
        _pagedInvoices.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _emitFiltered();
      },
    );
  }

  void _emitFiltered() {
    final sales = _pagedInvoices.whereType<SalesInvoice>().toList();
    final purchases = _pagedInvoices.whereType<PurchaseInvoice>().toList();
    final all = [...sales, ...purchases];

    final paidCount = all.where((invoice) {
      if (invoice is SalesInvoice) {
        return invoice.paymentStatus == PaymentStatus.cash;
      }
      if (invoice is PurchaseInvoice) {
        return invoice.paymentStatus == PaymentStatus.cash;
      }
      return false;
    }).length;

    final debtCount = all.where((invoice) {
      if (invoice is SalesInvoice) {
        return invoice.paymentStatus == PaymentStatus.debt;
      }
      if (invoice is PurchaseInvoice) {
        return invoice.paymentStatus == PaymentStatus.debt;
      }
      return false;
    }).length;

    final totalAmount = all.fold<double>(0, (sum, invoice) {
      if (invoice is SalesInvoice) return sum + invoice.totalAmount;
      if (invoice is PurchaseInvoice) return sum + invoice.totalAmount;
      return sum;
    });

    emit(
      InvoiceFiltered(
        salesInvoices: sales,
        purchaseInvoices: purchases,
        totalCount: all.length,
        paidCount: paidCount,
        pendingCount: debtCount,
        totalAmount: totalAmount,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,
      ),
    );
  }

  Future<void> getSalesInvoices() => loadFirstPage();

  Future<void> getPurchaseInvoices() => loadFirstPage();

  Future<void> getAllInvoices() => loadFirstPage();

  // CRUD operations
  Future<bool> createSalesInvoice(SalesInvoice invoice) async {
    final result = await _repository.createSalesInvoice(invoice);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(InvoiceError(failure.message));
        return false;
      },
      (_) {
        _dataChanges.notifyChanged(DataDomain.invoices);
        return true;
      },
    );
  }

  Future<bool> createPurchaseInvoice(PurchaseInvoice invoice) async {
    final result = await _repository.createPurchaseInvoice(invoice);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(InvoiceError(failure.message));
        return false;
      },
      (_) {
        _dataChanges.notifyChanged(DataDomain.invoices);
        return true;
      },
    );
  }

  Future<bool> updateSalesInvoice(SalesInvoice invoice) async {
    final snapshot = List<dynamic>.from(_pagedInvoices);
    if (_replaceInvoice(invoice)) _emitFiltered();

    final result = await _repository.updateSalesInvoice(invoice);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        _pagedInvoices
          ..clear()
          ..addAll(snapshot);
        emit(InvoiceError(failure.message));
        _emitFiltered();
        return false;
      },
      (_) {
        _dataChanges.notifyChanged(DataDomain.invoices);
        return true;
      },
    );
  }

  Future<bool> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    final snapshot = List<dynamic>.from(_pagedInvoices);
    if (_replaceInvoice(invoice)) _emitFiltered();

    final result = await _repository.updatePurchaseInvoice(invoice);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        _pagedInvoices
          ..clear()
          ..addAll(snapshot);
        emit(InvoiceError(failure.message));
        _emitFiltered();
        return false;
      },
      (_) {
        _dataChanges.notifyChanged(DataDomain.invoices);
        return true;
      },
    );
  }

  Future<void> deleteSalesInvoice(String id) async {
    final snapshot = List<dynamic>.from(_pagedInvoices);
    final previousOffset = _offset;
    if (_removeInvoice(id)) _emitFiltered();

    final result = await _repository.deleteSalesInvoice(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        _pagedInvoices
          ..clear()
          ..addAll(snapshot);
        _offset = previousOffset;
        emit(InvoiceError(failure.message));
        _emitFiltered();
      },
      (_) {
        emit(const SalesInvoiceDeleted());
        _emitFiltered();
        _dataChanges.notifyChangedAll([
          DataDomain.invoices,
          DataDomain.customerDebts,
        ]);
      },
    );
  }

  Future<void> deletePurchaseInvoice(String id) async {
    final snapshot = List<dynamic>.from(_pagedInvoices);
    final previousOffset = _offset;
    if (_removeInvoice(id)) _emitFiltered();

    final result = await _repository.deletePurchaseInvoice(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        _pagedInvoices
          ..clear()
          ..addAll(snapshot);
        _offset = previousOffset;
        emit(InvoiceError(failure.message));
        _emitFiltered();
      },
      (_) {
        emit(const PurchaseInvoiceDeleted());
        _emitFiltered();
        _dataChanges.notifyChangedAll([
          DataDomain.invoices,
          DataDomain.supplierDebts,
        ]);
      },
    );
  }

  bool _replaceInvoice(dynamic invoice) {
    final index = _pagedInvoices.indexWhere((item) => item.id == invoice.id);
    if (index == -1) return false;
    _pagedInvoices[index] = invoice;
    return true;
  }

  bool _removeInvoice(String id) {
    final index = _pagedInvoices.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    _pagedInvoices.removeAt(index);
    if (_offset > 0) _offset--;
    return true;
  }

  // Delete sales invoice and reduce customer balance if it was a debt invoice
  Future<void> deleteSalesInvoiceWithBalanceAdjustment(
    SalesInvoice invoice,
  ) async {
    final snapshot = List<dynamic>.from(_pagedInvoices);
    final previousOffset = _offset;
    if (_removeInvoice(invoice.id)) _emitFiltered();

    void rollback(String message) {
      _pagedInvoices
        ..clear()
        ..addAll(snapshot);
      _offset = previousOffset;
      emit(InvoiceError(message));
      _emitFiltered();
    }

    try {
      // If the invoice was not paid (debt), reduce the customer balance
      if (invoice.paymentStatus == PaymentStatus.debt &&
          invoice.customerId != null) {
        final amountToReduce = invoice.remainingAmount > 0
            ? invoice.remainingAmount
            : invoice.totalAmount;

        if (amountToReduce > 0) {
          // Update customer balance via RPC (negative to subtract)
          await _repository.updateCustomerBalance(
            invoice.customerId!,
            -amountToReduce,
          );
        }
      }

      // Now delete the invoice
      final result = await _repository.deleteSalesInvoice(invoice.id);
      if (isClosed) return;
      result.fold((failure) => rollback(failure.message), (_) {
        emit(const SalesInvoiceDeleted());
        _emitFiltered();
        _dataChanges.notifyChangedAll([
          DataDomain.invoices,
          DataDomain.customerDebts,
        ]);
      });
    } catch (e) {
      if (!isClosed) rollback('فشل حذف الفاتورة: ${e.toString()}');
    }
  }

  Future<void> getSalesInvoiceById(String id) async {
    emit(const InvoiceLoading());
    final result = await _repository.getSalesInvoiceById(id);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoice) => emit(SalesInvoiceLoaded(invoice)),
    );
  }

  Future<void> getPurchaseInvoiceById(String id) async {
    emit(const InvoiceLoading());
    final result = await _repository.getPurchaseInvoiceById(id);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoice) => emit(PurchaseInvoiceLoaded(invoice)),
    );
  }

  // New filtering methods
  void setTypeFilter(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    loadFirstPage();
  }

  void setStatusFilter(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadFirstPage();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), loadFirstPage);
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    loadFirstPage();
  }

  void clearFilters() {
    _selectedType = 'sale';
    _selectedStatus = 'all';
    _searchQuery = '';
    _dateFrom = null;
    _dateTo = null;
    loadFirstPage();
  }

  // Invoice creation methods
  void _emitFormUpdated(String updateType) {
    emit(
      InvoiceFormUpdated(
        updateType: updateType,
        revision: ++_formUpdateRevision,
      ),
    );
  }

  void setInvoiceType(String type) {
    _invoiceType = type;
    if (type == 'sale') {
      _selectedSupplierId = null;
    } else {
      _selectedCustomerId = null;
    }
    _emitFormUpdated('invoiceType');
  }

  void setCustomer(String? customerId) {
    _selectedCustomerId = customerId;
    _emitFormUpdated('customer');
  }

  void setSupplier(String? supplierId) {
    _selectedSupplierId = supplierId;
    _emitFormUpdated('supplier');
  }

  void addInvoiceItem(InvoiceItem item) {
    _invoiceItems.insert(0, item);
    // Calculate totals immediately after adding item
    _calculateAndUpdateTotals();
    _emitFormUpdated('addItem');
  }

  void removeInvoiceItem(int index) {
    if (index >= 0 && index < _invoiceItems.length) {
      _invoiceItems.removeAt(index);
      // Calculate totals immediately after removing item
      _calculateAndUpdateTotals();
      _emitFormUpdated('removeItem');
    }
  }

  void updateItemPrice(int index, double newPrice) {
    if (index >= 0 && index < _invoiceItems.length) {
      final item = _invoiceItems[index];
      _invoiceItems[index] = InvoiceItem(
        measurement: item.measurement,
        unit: item.unit,
        productId: item.productId,
        productName: item.productName ?? 'null_data',
        quantity: item.quantity ?? 0,
        unitPrice: newPrice,
        purchasePrice: item.purchasePrice ?? 0.0,
        totalPrice: newPrice * (item.quantity ?? 0).toDouble(),
      );
      _calculateAndUpdateTotals();
      _emitFormUpdated('updatePrice');
    }
  }

  void _calculateAndUpdateTotals() {
    if (_paymentType == 'cash') {
      _paidAmount = calculateGrandTotal();
    }

    _emitFormUpdated('calculateTotals');
  }

  void removeInvoiceItemById(String itemId) {
    _invoiceItems.removeWhere((item) => item.id == itemId);
    // Calculate totals immediately after removing item
    _calculateAndUpdateTotals();
    _emitFormUpdated('removeItem');
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    // If payment type is cash, update paidAmount to match new grand total
    if (_paymentType == 'cash') {
      _paidAmount = calculateGrandTotal();
    }
    _emitFormUpdated('discount');
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    _emitFormUpdated('paidAmount');
  }

  void setNotes(String notes) {
    _notes = notes;
    _emitFormUpdated('notes');
  }

  void setReference(String reference) {
    _reference = reference;
    _emitFormUpdated('reference');
  }

  void setProject(String project) {
    _project = project;
    _emitFormUpdated('project');
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _emitFormUpdated('paymentMethod');
  }

  void setPaymentType(String? type) {
    _paymentType = type;
    _paidAmount = type == 'cash' ? calculateGrandTotal() : 0.0;
    _emitFormUpdated('paymentType');
  }

  void setStatus(String status) {
    _status = status;
    _emitFormUpdated('status');
  }

  void clearInvoiceData() {
    _invoiceType = 'sale';
    _selectedCustomerId = null;
    _selectedSupplierId = null;
    _invoiceItems.clear();
    _discountAmount = 0.0;
    _paidAmount = 0.0;
    _notes = '';
    _reference = '';
    _project = '';
    _paymentMethod = '';
    _paymentType = null;
    _status = 'completed';
    _emitFormUpdated('clearAll');
  }

  // Calculation methods
  double calculateSubtotal() {
    return _invoiceItems.fold<double>(
      0,
      (sum, item) => sum + (item.totalPrice ?? 0.0),
    );
  }

  double calculateDiscountAmount() {
    return _discountAmount;
  }

  double calculateGrandTotal() {
    return calculateSubtotal() - calculateDiscountAmount();
  }

  double calculateRemainingAmount() {
    return calculateGrandTotal() - _paidAmount;
  }

  bool get canSaveInvoice {
    if (_invoiceType == 'sale' && _selectedCustomerId == null) return false;
    if (_invoiceType == 'purchase' && _selectedSupplierId == null) return false;
    if (_invoiceItems.isEmpty) return false;
    if (_paymentType == null) return false;
    return true;
  }

  Future<bool> saveInvoice() async {
    if (!canSaveInvoice) {
      emit(InvoiceError('يرجى إكمال جميع الحقول المطلوبة'));
      return false;
    }

    emit(const InvoiceLoading());

    try {
      final now = DateTime.now();
      final invoiceNumber = _generateInvoiceNumber();
      final userID = await UserService.getUserId();
      if (userID == null) {
        emit(InvoiceError('تعذر تحديد المستخدم الحالي'));
        return false;
      }

      final paymentStatus = _paymentType == 'cash'
          ? PaymentStatus.cash
          : PaymentStatus.debt;
      _paidAmount = _paymentType == 'cash' ? calculateGrandTotal() : 0.0;

      if (_invoiceType == 'sale') {
        final salesInvoice = SalesInvoice(
          status: InvoiceStatus.fromString(_status),
          id: '', // Will be generated by Supabase
          userId: userID,
          invoiceNumber: invoiceNumber,
          customerId: _selectedCustomerId,
          invoiceDate: now,
          dueDate: now,
          subtotal: calculateSubtotal(),
          discountAmount: calculateDiscountAmount(),
          taxAmount: 0.0,
          taxPercentage: 0.0,
          shippingCost: 0.0,
          totalAmount: calculateGrandTotal(),
          paidAmount: _paidAmount,
          remainingAmount: calculateRemainingAmount(),
          paymentMethod: _paymentType == 'cash' ? 'cash' : 'debt',
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: _status == 'approved',
          createdAt: now,
          updatedAt: now,
          items: _invoiceItems
              .map(
                (item) => InvoiceItem(
                  measurement: item.measurement,
                  unit: item.unit,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  purchasePrice: item.purchasePrice,
                  totalPrice: item.totalPrice,
                  createdAt: now,
                ),
              )
              .toList(),
          totalPurchaseAmount: _invoiceItems.fold(
            0.0,
            (sum, item) =>
                sum + ((item.purchasePrice ?? 0.0) * (item.quantity ?? 0)),
          ),
          profit:
              calculateGrandTotal() -
              _invoiceItems.fold(
                0.0,
                (sum, item) =>
                    sum + ((item.purchasePrice ?? 0.0) * (item.quantity ?? 0)),
              ),
        );

        final created = await createSalesInvoice(salesInvoice);
        if (!created) return false;

        // If debt invoice, update customer balance
        if (_paymentType == 'debt' && _selectedCustomerId != null) {
          final amountToAdd = calculateRemainingAmount();
          if (amountToAdd > 0) {
            await _repository.updateCustomerBalance(
              _selectedCustomerId!,
              amountToAdd,
            );
            _dataChanges.notifyChanged(DataDomain.customerDebts);
          }
        }
      } else {
        final purchaseInvoice = PurchaseInvoice(
          status: InvoiceStatus.fromString(_status),
          id: '', // Will be generated by Supabase
          userId: userID,
          invoiceNumber: invoiceNumber,
          supplierId: _selectedSupplierId,
          invoiceDate: now,
          dueDate: now,
          subtotal: calculateSubtotal(),
          discountAmount: calculateDiscountAmount(),
          taxAmount: 0.0, // TODO: Implement tax calculation
          shippingCost: 0.0, // TODO: Implement shipping cost
          totalAmount: calculateGrandTotal(),
          paidAmount: _paidAmount,
          remainingAmount: calculateRemainingAmount(),
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: _status == 'approved',
          createdAt: now,
          updatedAt: now,
          items: _invoiceItems
              .map(
                (item) => InvoiceItem(
                  measurement: item.measurement,
                  unit: item.unit,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  purchasePrice: item.purchasePrice,
                  totalPrice: item.totalPrice,
                  createdAt: now,
                ),
              )
              .toList(),
        );

        final created = await createPurchaseInvoice(purchaseInvoice);
        if (!created) return false;

        if (_paymentType == 'debt' && _selectedSupplierId != null) {
          _dataChanges.notifyChanged(DataDomain.supplierDebts);
        }
      }

      clearInvoiceData();
      return true;
    } catch (e) {
      emit(InvoiceError('فشل حفظ الفاتورة: ${e.toString()}'));
      return false;
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final prefix = _invoiceType == 'sale' ? 'INV' : 'PUR';
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return '$prefix-$dateStr-$random';
  }

  // Yeni method: herhangi bir faturanın durumunu günceller
  Future<void> updateInvoiceStatus(dynamic invoice, String newStatus) async {
    try {
      if (invoice is SalesInvoice) {
        final updatedStatus = PaymentStatus.values.firstWhere(
          (e) => e.name == newStatus,
          orElse: () => PaymentStatus.cash,
        );

        final updatedInvoice = invoice.copyWith(
          paymentStatus: updatedStatus,
          updatedAt: DateTime.now(),
        );

        final updated = await updateSalesInvoice(updatedInvoice);
        if (updated) _dataChanges.notifyChanged(DataDomain.customerDebts);
      } else if (invoice is PurchaseInvoice) {
        final updatedStatus = InvoiceStatus.values.firstWhere(
          (e) => e.name == newStatus,
          orElse: () => InvoiceStatus.draft,
        );

        final updatedInvoice = invoice.copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );

        final updated = await updatePurchaseInvoice(updatedInvoice);
        if (updated) _dataChanges.notifyChanged(DataDomain.supplierDebts);
      }
    } catch (e) {
      emit(InvoiceError('فشل تحديث حالة الفاتورة: ${e.toString()}'));
    }
  }

  // Update payment status and adjust customer balance accordingly
  Future<bool> updateInvoicePaymentStatusWithBalance(
    SalesInvoice invoice,
    String newStatus,
  ) async {
    try {
      final updatedStatus = PaymentStatus.values.firstWhere(
        (e) => e.name == newStatus,
        orElse: () => PaymentStatus.cash,
      );

      final updatedInvoice = invoice.copyWith(
        paymentStatus: updatedStatus,
        updatedAt: DateTime.now(),
      );

      // If marking as cash (paid), reduce the customer balance
      if (newStatus == 'cash' && invoice.paymentStatus == PaymentStatus.debt) {
        // Calculate the amount to reduce from customer balance
        final amountToReduce = invoice.remainingAmount > 0
            ? invoice.remainingAmount
            : invoice.totalAmount;

        if (amountToReduce > 0 && invoice.customerId != null) {
          // Update customer balance via RPC
          await _repository.updateCustomerBalance(
            invoice.customerId!,
            -amountToReduce, // Negative to subtract from balance
          );
        }
      }

      final updated = await updateSalesInvoice(updatedInvoice);
      if (updated) _dataChanges.notifyChanged(DataDomain.customerDebts);
      return updated;
    } catch (e) {
      emit(InvoiceError('فشل تحديث حالة الدفع: ${e.toString()}'));
      return false;
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
