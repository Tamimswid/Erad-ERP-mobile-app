import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:erad/features/invoices/data/repositories/edit_invoice_repository.dart';

part 'edit_invoice_state.dart';

class EditInvoiceCubit extends Cubit<EditInvoiceState> {
  final EditInvoiceRepository _repository;
  
  dynamic _originalInvoice;
  bool _isSales = true;

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

  EditInvoiceCubit(this._repository) : super(EditInvoiceInitial());

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

  Future<void> loadSalesInvoice(String id) async {
    emit(EditInvoiceLoading());
    
    final result = await _repository.getSalesInvoiceForEdit(id);
    result.fold(
      (failure) => emit(EditInvoiceError(failure.message)),
      (invoice) {
        _originalInvoice = invoice;
        _isSales = true;
        
        final invoiceItems = invoice.items ?? [];
        _items = invoiceItems.map((item) => InvoiceItem(
          id: item.id ?? '',
          productId: item.productId ?? '',
          productName: item.productName ?? '',
          quantity: item.quantity ?? 1,
          unitPrice: item.unitPrice ?? 0,
          discountAmount: item.discountAmount ?? 0,
          totalPrice: item.totalPrice ?? 0,
          unit: item.unit,
          measurement: item.measurement,
          createdAt: item.createdAt ?? DateTime.now(),
        )).toList();
        
        _customerId = invoice.customerId;
        _invoiceDate = invoice.invoiceDate ?? DateTime.now();
        _dueDate = invoice.dueDate;
        _discountAmount = invoice.discountAmount ?? 0;
        _paidAmount = invoice.paidAmount ?? 0;
        _notes = invoice.notes ?? '';
        _paymentMethod = invoice.paymentMethod ?? 'cash';
        _paymentType = invoice.paymentStatus == PaymentStatus.cash ? 'cash' : 'debt';
        
        emit(EditInvoiceLoaded(
          invoice: invoice,
          isSales: true,
          items: _items,
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
        ));
      },
    );
  }

  Future<void> loadPurchaseInvoice(String id) async {
    emit(EditInvoiceLoading());
    
    final result = await _repository.getPurchaseInvoiceForEdit(id);
    result.fold(
      (failure) => emit(EditInvoiceError(failure.message)),
      (invoice) {
        _originalInvoice = invoice;
        _isSales = false;
        
        final invoiceItems = invoice.items ?? [];
        _items = invoiceItems.map((item) => InvoiceItem(
          id: item.id ?? '',
          productId: item.productId ?? '',
          productName: item.productName ?? '',
          quantity: item.quantity ?? 1,
          unitPrice: item.unitPrice ?? 0,
          discountAmount: item.discountAmount ?? 0,
          totalPrice: item.totalPrice ?? 0,
          unit: item.unit,
          measurement: item.measurement,
          createdAt: item.createdAt ?? DateTime.now(),
        )).toList();
        
        _supplierId = invoice.supplierId;
        _invoiceDate = invoice.invoiceDate ;
        _dueDate = invoice.dueDate;
        _discountAmount = invoice.discountAmount;
        _paidAmount = invoice.paidAmount;
        _notes = invoice.notes ?? '';
        _paymentMethod = invoice.paymentStatus.name ;
        _paymentType = invoice.paymentStatus == PaymentStatus.cash ? 'cash' : 'debt';
        
        emit(EditInvoiceLoaded(
          invoice: invoice,
          isSales: false,
          items: _items,
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
        ));
      },
    );
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
    _discountAmount = amount;
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
    return _items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _discountAmount;
  }

  double _calculateRemaining() {
    return _calculateTotal() - _paidAmount;
  }

  void _emitUpdated() {
    if (_originalInvoice != null) {
      emit(EditInvoiceLoaded(
        invoice: _originalInvoice,
        isSales: _isSales,
        items: _items,
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
      ));
    }
  }

  bool get canSave {
    if (_isSales && _customerId == null) return false;
    if (!_isSales && _supplierId == null) return false;
    if (_items.isEmpty) return false;
    if (_invoiceDate == null) return false;
    return true;
  }

  Future<void> saveInvoice() async {
    if (!canSave) {
      emit(EditInvoiceError('يرجى إكمال جميع الحقول المطلوبة'));
      return;
    }

    emit(EditInvoiceLoading());

    try {
      final newItems = _items.map((item) => InvoiceItem(
        id: '',
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: item.discountAmount,
        totalPrice: item.totalPrice,
        unit: item.unit,
        measurement: item.measurement,
        createdAt: DateTime.now(),
      )).toList();

      final paymentStatus = _paymentType == 'cash' ? PaymentStatus.cash : PaymentStatus.debt;

      if (_isSales && _originalInvoice is SalesInvoice) {
        final original = _originalInvoice as SalesInvoice;
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
          paidAmount: _paidAmount,
          remainingAmount: _calculateRemaining(),
          paymentMethod: _paymentMethod,
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: original.isFinalized,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          status: original.status,
        );

        final result = await _repository.updateSalesInvoice(updatedInvoice, newItems);

        result.fold(
          (failure) => emit(EditInvoiceError(failure.message)),
          (invoice) {
            _originalInvoice = invoice;
            emit(const EditInvoiceUpdated('تم تحديث الفاتورة بنجاح'));
          },
        );
      } else if (!_isSales && _originalInvoice is PurchaseInvoice) {
        final original = _originalInvoice as PurchaseInvoice;
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
          paidAmount: _paidAmount,
          remainingAmount: _calculateRemaining(),
          paymentStatus: paymentStatus,
          notes: _notes.isEmpty ? null : _notes,
          isFinalized: original.isFinalized,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          status: original.status,
        );

        final result = await _repository.updatePurchaseInvoice(updatedInvoice, newItems);

        result.fold(
          (failure) => emit(EditInvoiceError(failure.message)),
          (invoice) {
            _originalInvoice = invoice;
            emit(const EditInvoiceUpdated('تم تحديث الفاتورة بنجاح'));
          },
        );
      }
    } catch (e) {
      emit(EditInvoiceError('فشل تحديث الفاتورة: ${e.toString()}'));
    }
  }
}