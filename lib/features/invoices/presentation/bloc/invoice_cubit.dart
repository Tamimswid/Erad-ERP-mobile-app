import 'dart:async';

import 'package:bloc/bloc.dart';
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
  final List<dynamic> _pagedInvoices = [];
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Timer? _searchDebounce;

  // New filtering state
  String _selectedType = 'sale';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Invoice creation state
  String _invoiceType = 'sale';
  String _debtType = 'debtor'; // 'debtor' or 'creditor'
  String? _selectedCustomerId;
  String? _selectedSupplierId;
  DateTime? _invoiceDate;
  DateTime? _dueDate;
  DateTime? _deliveryDate;
  List<InvoiceItem> _invoiceItems = [];
  double _discountAmount = 0.0;
  double _paidAmount = 0.0;
  String _notes = '';
  String _reference = '';
  String _project = '';
  String _paymentMethod = '';
  String _paymentType = 'debt'; // 'debt' or 'cash'
  String _status = 'completed';

  // Getters for accessing filter state
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // Getters for invoice creation state
  String get invoiceType => _invoiceType;
  String get debtType => _debtType;
  String? get selectedCustomerId => _selectedCustomerId;
  String? get selectedSupplierId => _selectedSupplierId;
  DateTime? get invoiceDate => _invoiceDate;
  DateTime? get dueDate => _dueDate;
  DateTime? get deliveryDate => _deliveryDate;
  List<InvoiceItem> get invoiceItems => _invoiceItems;
  double get discountAmount => _discountAmount;
  double get paidAmount => _paidAmount;
  String get notes => _notes;
  String get reference => _reference;
  String get project => _project;
  String get paymentMethod => _paymentMethod;
  String get paymentType => _paymentType;
  String get status => _status;

  InvoiceCubit(this._repository) : super(const InvoiceInitial()) {
    // Initialize with default values for new invoice creation
    _invoiceDate = DateTime.now();
    _dueDate = DateTime.now();
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _pagedInvoices.clear();
    emit(const InvoiceLoading());

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
      result.fold((failure) => emit(InvoiceError(failure.message)), (page) {
        _pagedInvoices.addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _emitFiltered();
      });
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
    result.fold((failure) => emit(InvoiceError(failure.message)), (page) {
      _pagedInvoices.addAll(page.items);
      _offset = page.items.length;
      _hasMore = page.hasMore;
      _emitFiltered();
    });
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
  Future<void> createSalesInvoice(SalesInvoice invoice) async {
    emit(const InvoiceLoading());
    final result = await _repository.createSalesInvoice(invoice);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (success) => getSalesInvoices(),
    );
  }

  Future<void> createPurchaseInvoice(PurchaseInvoice invoice) async {
    emit(const InvoiceLoading());
    final result = await _repository.createPurchaseInvoice(invoice);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (success) => getPurchaseInvoices(),
    );
  }

  Future<void> updateSalesInvoice(
    SalesInvoice invoice, {
    bool optimisticUpdate = false,
  }) async {
    if (!optimisticUpdate) {
      emit(const InvoiceLoading());
    }
    final result = await _repository.updateSalesInvoice(invoice);
    result.fold((failure) => emit(InvoiceError(failure.message)), (success) {
      if (!optimisticUpdate) {
        getSalesInvoices();
      }
      // If optimistic update, real-time stream will handle the update
    });
  }

  Future<void> updatePurchaseInvoice(
    PurchaseInvoice invoice, {
    bool optimisticUpdate = false,
  }) async {
    if (!optimisticUpdate) {
      emit(const InvoiceLoading());
    }
    final result = await _repository.updatePurchaseInvoice(invoice);
    result.fold((failure) => emit(InvoiceError(failure.message)), (success) {
      if (!optimisticUpdate) {
        getPurchaseInvoices();
      }
      // If optimistic update, real-time stream will handle the update
    });
  }

  Future<void> deleteSalesInvoice(String id) async {
    emit(const InvoiceLoading());
    final result = await _repository.deleteSalesInvoice(id);
    result.fold((failure) => emit(InvoiceError(failure.message)), (success) {
      emit(SalesInvoiceDeleted());
      getSalesInvoices();
    });
  }

  Future<void> deletePurchaseInvoice(String id) async {
    emit(const InvoiceLoading());
    final result = await _repository.deletePurchaseInvoice(id);
    result.fold((failure) => emit(InvoiceError(failure.message)), (success) {
      emit(PurchaseInvoiceDeleted());
      getPurchaseInvoices();
    });
  }

  // Delete sales invoice and reduce customer balance if it was a debt invoice
  Future<void> deleteSalesInvoiceWithBalanceAdjustment(
    SalesInvoice invoice,
  ) async {
    try {
      emit(const InvoiceLoading());

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
      result.fold(
        (failure) => emit(InvoiceError(failure.message)),
        (success) => getSalesInvoices(),
      );
    } catch (e) {
      emit(InvoiceError('فشل حذف الفاتورة: ${e.toString()}'));
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
  void setInvoiceType(String type) {
    _invoiceType = type;
    if (type == 'sale') {
      _selectedSupplierId = null;
    } else {
      _selectedCustomerId = null;
    }
    emit(InvoiceFormUpdated(updateType: 'invoiceType'));
  }

  void setDebtType(String type) {
    _debtType = type;
    emit(InvoiceFormUpdated(updateType: 'debtType'));
  }

  void setCustomer(String? customerId) {
    _selectedCustomerId = customerId;
    emit(InvoiceFormUpdated(updateType: 'customer'));
  }

  void setSupplier(String? supplierId) {
    _selectedSupplierId = supplierId;
    emit(InvoiceFormUpdated(updateType: 'supplier'));
  }

  void setInvoiceDate(DateTime? date) {
    print('DEBUG: setInvoiceDate called with: $date');
    _invoiceDate = date;
    print('DEBUG: _invoiceDate set to: $_invoiceDate');
    emit(InvoiceFormUpdated(updateType: 'invoiceDate'));
  }

  void setDueDate(DateTime? date) {
    _dueDate = date;
    emit(InvoiceFormUpdated(updateType: 'dueDate'));
  }

  void setDeliveryDate(DateTime? date) {
    _deliveryDate = date;
    emit(InvoiceFormUpdated(updateType: 'deliveryDate'));
  }

  void addInvoiceItem(InvoiceItem item) {
    _invoiceItems.insert(0, item);
    // Calculate totals immediately after adding item
    _calculateAndUpdateTotals();
    emit(InvoiceFormUpdated(updateType: 'addItem'));
  }

  void removeInvoiceItem(int index) {
    if (index >= 0 && index < _invoiceItems.length) {
      _invoiceItems.removeAt(index);
      // Calculate totals immediately after removing item
      _calculateAndUpdateTotals();
      emit(InvoiceFormUpdated(updateType: 'removeItem'));
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
      emit(InvoiceFormUpdated(updateType: 'updatePrice'));
    }
  }

  void _calculateAndUpdateTotals() {
    // This method ensures totals are calculated and ready for UI
    final subtotal = calculateSubtotal();
    final discountAmount = calculateDiscountAmount();
    final grandTotal = calculateGrandTotal();

    // If payment type is cash, update paidAmount to match grand total
    if (_paymentType == 'cash') {
      _paidAmount = grandTotal;
    }

    final remaining = calculateRemainingAmount();

    // Debug: Log calculated values (can be removed in production)
    print(
      'DEBUG: Totals calculated - Subtotal: $subtotal, Discount: $discountAmount, Grand Total: $grandTotal, Paid: $_paidAmount, Remaining: $remaining',
    );

    // Force UI to update with new totals
    emit(InvoiceFormUpdated(updateType: 'calculateTotals'));
  }

  void removeInvoiceItemById(String itemId) {
    _invoiceItems.removeWhere((item) => item.id == itemId);
    // Calculate totals immediately after removing item
    _calculateAndUpdateTotals();
    emit(InvoiceFormUpdated(updateType: 'removeItem'));
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    // If payment type is cash, update paidAmount to match new grand total
    if (_paymentType == 'cash') {
      _paidAmount = calculateGrandTotal();
    }
    emit(InvoiceFormUpdated(updateType: 'discount'));
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    emit(InvoiceFormUpdated(updateType: 'paidAmount'));
  }

  void setNotes(String notes) {
    _notes = notes;
    emit(InvoiceFormUpdated(updateType: 'notes'));
  }

  void setReference(String reference) {
    _reference = reference;
    emit(InvoiceFormUpdated(updateType: 'reference'));
  }

  void setProject(String project) {
    _project = project;
    emit(InvoiceFormUpdated(updateType: 'project'));
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    emit(InvoiceFormUpdated(updateType: 'paymentMethod'));
  }

  void setPaymentType(String type) {
    _paymentType = type;
    // Automatically update paidAmount based on payment type
    if (type == 'cash') {
      _paidAmount = calculateGrandTotal();
    } else {
      _paidAmount = 0.0;
    }
    emit(InvoiceFormUpdated(updateType: 'paymentType'));
  }

  void setStatus(String status) {
    _status = status;
    emit(InvoiceFormUpdated(updateType: 'status'));
  }

  void clearInvoiceData() {
    print('DEBUG: clearInvoiceData called - resetting to defaults');
    _invoiceType = 'sale';
    _debtType = 'debtor';
    _selectedCustomerId = null;
    _selectedSupplierId = null;
    // Reset to defaults instead of null to avoid validation issues
    _invoiceDate = DateTime.now();
    _dueDate = DateTime.now();
    _deliveryDate = null;
    _invoiceItems.clear();
    _discountAmount = 0.0;
    _paidAmount = 0.0;
    _notes = '';
    _reference = '';
    _project = '';
    _paymentMethod = '';
    _paymentType = 'debt';
    _status = 'completed';
    print('DEBUG: clearInvoiceData - reset invoice date to: $_invoiceDate');
    emit(InvoiceFormUpdated(updateType: 'clearAll'));
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
    print('DEBUG: Invoice Type: $_invoiceType');
    print('DEBUG: Customer ID: $_selectedCustomerId');
    print('DEBUG: Supplier ID: $_selectedSupplierId');
    print('DEBUG: Invoice Items Count: ${_invoiceItems.length}');
    print('DEBUG: Invoice Date: $_invoiceDate');

    if (_invoiceType == 'sale' && _selectedCustomerId == null) {
      print('DEBUG: Failed - Sale type requires customer');
      return false;
    }
    if (_invoiceType == 'purchase' && _selectedSupplierId == null) {
      print('DEBUG: Failed - Purchase type requires supplier');
      return false;
    }
    if (_invoiceItems.isEmpty) {
      print('DEBUG: Failed - No invoice items');
      return false;
    }
    if (_invoiceDate == null) {
      print('DEBUG: Failed - No invoice date');
      return false;
    }
    print('DEBUG: All validations passed!');
    return true;
  }

  Future<void> saveInvoice() async {
    if (!canSaveInvoice) {
      emit(InvoiceError('يرجى إكمال جميع الحقول المطلوبة'));
      return;
    }

    emit(const InvoiceLoading());

    try {
      final now = DateTime.now();
      final invoiceNumber = _generateInvoiceNumber();
      final userID = await UserService.getUserId();

      // Set paidAmount based on paymentType before saving
      if (_paymentType == 'cash') {
        _paidAmount = calculateGrandTotal();
      } else {
        _paidAmount = 0.0;
      }

      print('DEBUG: Saving invoice with type: $_invoiceType');
      print('DEBUG: Payment Type: $_paymentType, Paid Amount: $_paidAmount');
      print(
        'DEBUG: Grand Total: ${calculateGrandTotal()}, Remaining: ${calculateRemainingAmount()}',
      );
      print('DEBUG: Payment Status: ${_getPaymentStatus()}');
      print('DEBUG: Invoice Number: $invoiceNumber');
      print('DEBUG: Items count: ${_invoiceItems.length}');
      print(
        'DEBUG: Items total purchase: ${_invoiceItems.fold(0.0, (sum, item) => sum + ((item.purchasePrice ?? 0.0) * (item.quantity ?? 0)))}',
      );

      if (_invoiceType == 'sale') {
        final salesInvoice = SalesInvoice(
          status: InvoiceStatus.fromString(status),
          id: '', // Will be generated by Supabase
          userId: userID!,
          invoiceNumber: invoiceNumber,
          customerId: _selectedCustomerId,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: calculateSubtotal(),
          discountAmount: calculateDiscountAmount(),
          taxAmount: 0.0,
          taxPercentage: 0.0,
          shippingCost: 0.0,
          totalAmount: calculateGrandTotal(),
          paidAmount: _paidAmount,
          remainingAmount: calculateRemainingAmount(),
          paymentMethod: _paymentMethod.isEmpty ? 'cash' : _paymentMethod,
          paymentStatus: _getPurchasePaymentStatus(),
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

        print('DEBUG: Creating sales invoice: ${salesInvoice.toJson()}');
        await createSalesInvoice(salesInvoice);

        // If debt invoice, update customer balance
        if (_paymentType == 'debt' && _selectedCustomerId != null) {
          final amountToAdd = calculateRemainingAmount();
          if (amountToAdd > 0) {
            print(
              'DEBUG: Updating customer balance for debt invoice: +$amountToAdd',
            );
            print('DEBUG: Customer ID: $_selectedCustomerId');
            try {
              final result = await _repository.updateCustomerBalance(
                _selectedCustomerId!,
                amountToAdd, // Positive to add to balance
              );
              result.fold(
                (failure) => print(
                  'DEBUG: ERROR updating customer balance: ${failure.message}',
                ),
                (success) =>
                    print('DEBUG: Customer balance updated successfully'),
              );
            } catch (e, stackTrace) {
              print('DEBUG: EXCEPTION during balance update: $e');
              print('DEBUG: Stack trace: $stackTrace');
            }
          }
        }
      } else {
        final purchaseInvoice = PurchaseInvoice(
          status: InvoiceStatus.fromString(status),
          id: '', // Will be generated by Supabase
          userId: userID!,
          invoiceNumber: invoiceNumber,
          supplierId: _selectedSupplierId,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: calculateSubtotal(),
          discountAmount: calculateDiscountAmount(),
          taxAmount: 0.0, // TODO: Implement tax calculation
          shippingCost: 0.0, // TODO: Implement shipping cost
          totalAmount: calculateGrandTotal(),
          paidAmount: _paidAmount,
          remainingAmount: calculateRemainingAmount(),
          paymentStatus: _getPurchasePaymentStatus(),
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

        print('DEBUG: Creating purchase invoice: ${purchaseInvoice.toJson()}');
        await createPurchaseInvoice(purchaseInvoice);
      }

      print('DEBUG: Invoice saved successfully!');
      clearInvoiceData();
    } catch (e) {
      print('DEBUG: Error saving invoice: $e');
      emit(InvoiceError('فشل حفظ الفاتورة: ${e.toString()}'));
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

  PaymentStatus _getPaymentStatus() {
    final remaining = calculateRemainingAmount();
    if (remaining <= 0) return PaymentStatus.cash;
    return PaymentStatus.debt;
  }

  PaymentStatus _getPurchasePaymentStatus() {
    final remaining = calculateRemainingAmount();
    if (remaining <= 0) return PaymentStatus.cash;
    if (_invoiceDate != null &&
        DateTime.now().isAfter(
          _dueDate ?? _invoiceDate!.add(const Duration(days: 30)),
        )) {
      return PaymentStatus.debt;
    }
    return PaymentStatus.debt;
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

        await updateSalesInvoice(updatedInvoice);
      } else if (invoice is PurchaseInvoice) {
        final updatedStatus = InvoiceStatus.values.firstWhere(
          (e) => e.name == newStatus,
          orElse: () => InvoiceStatus.draft,
        );

        final updatedInvoice = invoice.copyWith(
          status: updatedStatus,
          updatedAt: DateTime.now(),
        );

        await updatePurchaseInvoice(updatedInvoice);
      }
    } catch (e) {
      emit(InvoiceError('فشل تحديث حالة الفاتورة: ${e.toString()}'));
    }
  }

  // Update payment status and adjust customer balance accordingly
  Future<void> updateInvoicePaymentStatusWithBalance(
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

      await updateSalesInvoice(updatedInvoice);
    } catch (e) {
      emit(InvoiceError('فشل تحديث حالة الدفع: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
