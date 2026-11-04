import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/data/repositories/edit_invoice_repository.dart';
import 'package:erad/features/products/data/models/product.dart';

part 'edit_invoice_state.dart';

class EditInvoiceCubit extends Cubit<EditInvoiceState> {
  static const _placeholder = 'null_data';

  final EditInvoiceRepository _repository;
  final DataChangeNotifier _dataChanges;

  dynamic _originalInvoice;
  bool _isSales = true;
  int _revision = 0;
  bool _isSaving = false;
  List<ProductModel> _productCatalog = const [];

  List<InvoiceItem> _items = [];
  String? _customerId;
  String? _supplierId;
  DateTime? _invoiceDate;
  DateTime? _dueDate;
  double _discountAmount = 0;
  double _paidAmount = 0;
  String _notes = '';
  String _paymentMethod = 'cash';
  String _paymentType = 'cash';

  EditInvoiceCubit(this._repository, this._dataChanges)
    : super(EditInvoiceInitial());

  String? get customerId => _customerId;
  String? get supplierId => _supplierId;
  DateTime? get invoiceDate => _invoiceDate;
  DateTime? get dueDate => _dueDate;
  List<InvoiceItem> get items => _items;
  double get discountAmount => _discountAmount;
  double get paidAmount => _paidAmount;
  String get notes => _notes;
  String get paymentMethod => _paymentMethod;
  String get paymentType => _paymentType;
  bool get isSales => _isSales;
  bool get isSaving => _isSaving;

  /// Full product list from the picker cubit; used to backfill names/units that
  /// older invoice rows stored as null or `null_data`.
  void setProductCatalog(List<ProductModel> products) {
    _productCatalog = products;
  }

  ProductModel? _productFor(InvoiceItem item) {
    final id = item.productId?.trim() ?? '';
    if (id.isNotEmpty && id != _placeholder) {
      for (final product in _productCatalog) {
        if (product.id == id) return product;
      }
    }
    final name = item.productName?.trim() ?? '';
    if (name.isNotEmpty && name != _placeholder) {
      for (final product in _productCatalog) {
        if (product.name == name) return product;
      }
    }
    return null;
  }

  String _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed == _placeholder ? '' : trimmed;
  }

  String displayName(InvoiceItem item) {
    final stored = _clean(item.productName);
    if (stored.isNotEmpty) return stored;
    return _productFor(item)?.name ?? '';
  }

  String displayUnit(InvoiceItem item) {
    final stored = _clean(item.unit);
    if (stored.isNotEmpty) return stored;
    return _productFor(item)?.unit ?? '';
  }

  String displayMeasurement(InvoiceItem item) {
    final stored = _clean(item.measurement);
    if (stored.isNotEmpty) return stored;
    return _productFor(item)?.measurement ?? '';
  }

  /// "name measurement unit" — the same format used by the product cards.
  String displayLabel(InvoiceItem item) {
    return [
      displayName(item),
      displayMeasurement(item),
      displayUnit(item),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  List<InvoiceItem> _resolvedItems() {
    return _items.map((item) {
      return InvoiceItem(
        id: item.id,
        productId: item.productId,
        productName: displayName(item),
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        purchasePrice: item.purchasePrice,
        discountAmount: item.discountAmount,
        totalPrice: item.totalPrice,
        unit: displayUnit(item),
        measurement: displayMeasurement(item),
        createdAt: item.createdAt,
      );
    }).toList();
  }

  Future<void> loadSalesInvoice(String id) async {
    emit(EditInvoiceLoading());

    final result = await _repository.getSalesInvoiceForEdit(id);
    result.fold((failure) => emit(EditInvoiceError(failure.message)), (
      invoice,
    ) {
      _originalInvoice = invoice;
      _isSales = true;

      final invoiceItems = invoice.items;
      _items = invoiceItems
          .map(
            (item) => InvoiceItem(
              id: item.id ?? '',
              productId: item.productId ?? '',
              productName: item.productName ?? '',
              quantity: item.quantity ?? 1,
              unitPrice: item.unitPrice ?? 0,
              purchasePrice: item.purchasePrice ?? 0,
              discountAmount: item.discountAmount ?? 0,
              totalPrice: item.totalPrice ?? 0,
              unit: item.unit,
              measurement: item.measurement,
              createdAt: item.createdAt ?? DateTime.now(),
            ),
          )
          .toList();

      _customerId = invoice.customerId;
      _invoiceDate = invoice.invoiceDate;
      _dueDate = invoice.dueDate;
      _discountAmount = invoice.discountAmount;
      _paidAmount = invoice.paidAmount;
      _notes = invoice.notes ?? '';
      _paymentMethod = invoice.paymentMethod;
      _paymentType = invoice.paymentStatus == PaymentStatus.cash
          ? 'cash'
          : 'debt';

      emit(
        EditInvoiceLoaded(
          invoice: invoice,
          isSales: true,
          items: List<InvoiceItem>.unmodifiable(_items),
          customerId: _customerId,
          supplierId: null,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: _calculateSubtotal(),
          discountAmount: _discountAmount,
          totalAmount: _calculateTotal(),
          paidAmount: _paidAmount,
          remainingAmount: _calculateRemaining(),
          notes: _notes,
          paymentMethod: _paymentMethod,
          paymentType: _paymentType,
          revision: ++_revision,
        ),
      );
    });
  }

  Future<void> loadPurchaseInvoice(String id) async {
    emit(EditInvoiceLoading());

    final result = await _repository.getPurchaseInvoiceForEdit(id);
    result.fold((failure) => emit(EditInvoiceError(failure.message)), (
      invoice,
    ) {
      _originalInvoice = invoice;
      _isSales = false;

      final invoiceItems = invoice.items;
      _items = invoiceItems
          .map(
            (item) => InvoiceItem(
              id: item.id ?? '',
              productId: item.productId ?? '',
              productName: item.productName ?? '',
              quantity: item.quantity ?? 1,
              unitPrice: item.unitPrice ?? 0,
              purchasePrice: item.purchasePrice ?? 0,
              discountAmount: item.discountAmount ?? 0,
              totalPrice: item.totalPrice ?? 0,
              unit: item.unit,
              measurement: item.measurement,
              createdAt: item.createdAt ?? DateTime.now(),
            ),
          )
          .toList();

      _supplierId = invoice.supplierId;
      _invoiceDate = invoice.invoiceDate;
      _dueDate = invoice.dueDate;
      _discountAmount = invoice.discountAmount;
      _paidAmount = invoice.paidAmount;
      _notes = invoice.notes ?? '';
      _paymentMethod = invoice.paymentStatus.name;
      _paymentType = invoice.paymentStatus == PaymentStatus.cash
          ? 'cash'
          : 'debt';

      emit(
        EditInvoiceLoaded(
          invoice: invoice,
          isSales: false,
          items: List<InvoiceItem>.unmodifiable(_items),
          customerId: null,
          supplierId: _supplierId,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: _calculateSubtotal(),
          discountAmount: _discountAmount,
          totalAmount: _calculateTotal(),
          paidAmount: _paidAmount,
          remainingAmount: _calculateRemaining(),
          notes: _notes,
          paymentMethod: _paymentMethod,
          paymentType: _paymentType,
          revision: ++_revision,
        ),
      );
    });
  }

  void setCustomer(String? customerId) {
    _customerId = customerId;
    _emitUpdated();
  }

  void setSupplier(String? supplierId) {
    _supplierId = supplierId;
    _emitUpdated();
  }

  void setInvoiceDate(DateTime date) {
    _invoiceDate = date;
    _emitUpdated();
  }

  void setDueDate(DateTime? date) {
    _dueDate = date;
    _emitUpdated();
  }

  void addItem(InvoiceItem item) {
    _items.add(item);
    _emitUpdated();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _emitUpdated();
    }
  }

  void updateItem(int index, InvoiceItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      _emitUpdated();
    }
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount.isNaN || amount < 0 ? 0 : amount;
    _emitUpdated();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    _emitUpdated();
  }

  void setNotes(String notes) {
    _notes = notes;
    _emitUpdated();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _emitUpdated();
  }

  void setPaymentType(String type) {
    _paymentType = type;
    if (type == 'cash') {
      _paidAmount = _calculateTotal();
    } else {
      _paidAmount = 0;
    }
    _emitUpdated();
  }

  double _calculateSubtotal() {
    return _items.fold<double>(
      0,
      (sum, item) => sum + (item.totalPrice ?? 0.0),
    );
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _discountAmount;
  }

  double _calculateRemaining() {
    return _calculateTotal() - _safePaidAmount();
  }

  double _safePaidAmount() {
    final total = _calculateTotal();
    if (_paymentType == 'cash') return total;
    if (total <= 0) return 0;
    return _paidAmount.clamp(0.0, total).toDouble();
  }

  void _emitUpdated() {
    if (_originalInvoice == null) return;
    // A shrinking invoice must never leave a negative remaining balance.
    _paidAmount = _safePaidAmount();
    emit(
      EditInvoiceLoaded(
        invoice: _originalInvoice,
        isSales: _isSales,
        items: List<InvoiceItem>.unmodifiable(_items),
        customerId: _customerId,
        supplierId: _supplierId,
        invoiceDate: _invoiceDate ?? DateTime.now(),
        dueDate: _dueDate,
        subtotal: _calculateSubtotal(),
        discountAmount: _discountAmount,
        totalAmount: _calculateTotal(),
        paidAmount: _paidAmount,
        remainingAmount: _calculateRemaining(),
        notes: _notes,
        paymentMethod: _paymentMethod,
        paymentType: _paymentType,
        revision: ++_revision,
      ),
    );
  }

  double _calculatePurchaseTotal(List<InvoiceItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (item.purchasePrice ?? 0.0) * (item.quantity ?? 0),
    );
  }

  bool get canSave {
    if (_isSales && _customerId == null) return false;
    if (!_isSales && _supplierId == null) return false;
    if (_items.isEmpty) return false;
    if (_invoiceDate == null) return false;
    if (_discountAmount < 0 || _discountAmount > _calculateSubtotal()) {
      return false;
    }
    if (_items.any(
      (item) => (item.quantity ?? 0) <= 0 || displayName(item).isEmpty,
    )) {
      return false;
    }
    return true;
  }

  Future<bool> saveInvoice() async {
    if (_isSaving) return false;
    if (!canSave) {
      emit(EditInvoiceError('يرجى إكمال جميع الحقول المطلوبة'));
      _emitUpdated();
      return false;
    }

    _isSaving = true;
    try {
      final original = _originalInvoice;
      final newItems = _resolvedItems();
      final paymentStatus = _paymentType == 'cash'
          ? PaymentStatus.cash
          : PaymentStatus.debt;

      if (_isSales && original is SalesInvoice) {
        final purchaseTotal = _calculatePurchaseTotal(newItems);
        final updatedInvoice = SalesInvoice(
          id: original.id,
          userId: original.userId,
          invoiceNumber: original.invoiceNumber,
          customerId: _customerId,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: _calculateSubtotal(),
          discountAmount: _discountAmount,
          taxAmount: original.taxAmount,
          taxPercentage: original.taxPercentage,
          shippingCost: original.shippingCost,
          totalAmount: _calculateTotal(),
          paidAmount: _safePaidAmount(),
          remainingAmount: _calculateRemaining(),
          paymentMethod: _paymentType,
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: original.isFinalized,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          status: original.status,
          totalPurchaseAmount: purchaseTotal,
          profit: _calculateTotal() - purchaseTotal,
        );

        final result = await _repository.updateSalesInvoice(
          updatedInvoice,
          newItems,
        );

        final saved = result.fold<SalesInvoice?>((failure) {
          _failSave(failure.message);
          return null;
        }, (invoice) => invoice);
        if (saved == null) return false;

        await _adjustBalanceSafely(
          () => _adjustCustomerBalance(original, updatedInvoice),
        );
        _finishSave(saved, DataDomain.customerDebts);
        return true;
      }

      if (!_isSales && original is PurchaseInvoice) {
        final updatedInvoice = PurchaseInvoice(
          id: original.id,
          userId: original.userId,
          invoiceNumber: original.invoiceNumber,
          supplierId: _supplierId,
          invoiceDate: _invoiceDate!,
          dueDate: _dueDate,
          subtotal: _calculateSubtotal(),
          discountAmount: _discountAmount,
          taxAmount: original.taxAmount,
          shippingCost: original.shippingCost,
          totalAmount: _calculateTotal(),
          paidAmount: _safePaidAmount(),
          remainingAmount: _calculateRemaining(),
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: original.isFinalized,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          status: original.status,
        );

        final result = await _repository.updatePurchaseInvoice(
          updatedInvoice,
          newItems,
        );

        final saved = result.fold<PurchaseInvoice?>((failure) {
          _failSave(failure.message);
          return null;
        }, (invoice) => invoice);
        if (saved == null) return false;

        await _adjustBalanceSafely(
          () => _adjustSupplierBalance(original, updatedInvoice),
        );
        _finishSave(saved, DataDomain.supplierDebts);
        return true;
      }

      _failSave('تعذر تحديد نوع الفاتورة');
      return false;
    } catch (e) {
      _failSave('فشل تحديث الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _isSaving = false;
    }
  }

  void _finishSave(dynamic invoice, DataDomain debtDomain) {
    _originalInvoice = invoice;
    emit(const EditInvoiceUpdated('تم تحديث الفاتورة بنجاح'));
    _dataChanges.notifyChangedAll([DataDomain.invoices, debtDomain]);
  }

  void _failSave(String message) {
    emit(EditInvoiceError(message));
    _emitUpdated();
  }

  /// The invoice row is already persisted at this point; a balance sync failure
  /// must not be reported as a failed save.
  Future<void> _adjustBalanceSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  double _debtAmount(double total, PaymentStatus status) {
    return status == PaymentStatus.debt ? total : 0;
  }

  Future<void> _adjustCustomerBalance(
    SalesInvoice original,
    SalesInvoice updated,
  ) async {
    final oldDebt = _debtAmount(
      original.remainingAmount,
      original.paymentStatus,
    );
    final newDebt = _debtAmount(updated.remainingAmount, updated.paymentStatus);
    final oldId = original.customerId;
    final newId = updated.customerId;

    if (oldId == newId) {
      if (oldId == null) return;
      final delta = newDebt - oldDebt;
      if (delta.abs() < 0.01) return;
      await _repository.updateCustomerBalance(oldId, delta);
      return;
    }

    // The invoice moved to another customer: release the old debt and apply
    // the full new one instead of a delta against the wrong customer.
    if (oldId != null && oldDebt.abs() >= 0.01) {
      await _repository.updateCustomerBalance(oldId, -oldDebt);
    }
    if (newId != null && newDebt.abs() >= 0.01) {
      await _repository.updateCustomerBalance(newId, newDebt);
    }
  }

  Future<void> _adjustSupplierBalance(
    PurchaseInvoice original,
    PurchaseInvoice updated,
  ) async {
    final oldDebt = _debtAmount(
      original.remainingAmount,
      original.paymentStatus,
    );
    final newDebt = _debtAmount(updated.remainingAmount, updated.paymentStatus);
    final oldId = original.supplierId;
    final newId = updated.supplierId;

    if (oldId == newId) {
      if (oldId == null) return;
      final delta = newDebt - oldDebt;
      if (delta.abs() < 0.01) return;
      await _repository.updateSupplierBalance(oldId, delta);
      return;
    }

    if (oldId != null && oldDebt.abs() >= 0.01) {
      await _repository.updateSupplierBalance(oldId, -oldDebt);
    }
    if (newId != null && newDebt.abs() >= 0.01) {
      await _repository.updateSupplierBalance(newId, newDebt);
    }
  }
}
