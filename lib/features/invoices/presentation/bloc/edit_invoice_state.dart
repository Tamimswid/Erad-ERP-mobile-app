part of 'edit_invoice_cubit.dart';

// import 'package:erad/features/invoices/data/models/invoice_item.dart';

abstract class EditInvoiceState extends Equatable {
  const EditInvoiceState();

  @override
  List<Object?> get props => [];
}

class EditInvoiceInitial extends EditInvoiceState {}

class EditInvoiceLoading extends EditInvoiceState {}

class EditInvoiceLoaded extends EditInvoiceState {
  final dynamic invoice;
  final bool isSales;
  final List<InvoiceItem> items;
  final String? customerId;
  final String? supplierId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String notes;
  final String paymentMethod;
  final String paymentType;

  const EditInvoiceLoaded({
    required this.invoice,
    required this.isSales,
    required this.items,
    this.customerId,
    this.supplierId,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.notes,
    required this.paymentMethod,
    required this.paymentType,
  });

  @override
  List<Object?> get props => [
    invoice,
    isSales,
    items,
    customerId,
    supplierId,
    invoiceDate,
    dueDate,
    subtotal,
    discountAmount,
    totalAmount,
    paidAmount,
    remainingAmount,
    notes,
    paymentMethod,
    paymentType,
  ];
}

class EditInvoiceUpdated extends EditInvoiceState {
  final String message;

  const EditInvoiceUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class EditInvoiceError extends EditInvoiceState {
  final String message;

  const EditInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
