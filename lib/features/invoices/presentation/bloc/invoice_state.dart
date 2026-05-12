part of 'invoice_cubit.dart';

enum DateFilter {
  all,
  // today,
  // thisWeek,
  thisMonth,
  thisYear,
  custom,
}

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

// Sales Invoice States
class SalesInvoicesLoaded extends InvoiceState {
  final List<SalesInvoice> invoices;

  const SalesInvoicesLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

class FilteredSalesInvoicesLoaded extends InvoiceState {
  final List<SalesInvoice> invoices;
  final DateFilter filter;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilteredSalesInvoicesLoaded(this.invoices, this.filter, {this.startDate, this.endDate});

  @override
  List<Object?> get props => [invoices, filter, startDate, endDate];
}

class SalesInvoiceLoaded extends InvoiceState {
  final SalesInvoice invoice;

  const SalesInvoiceLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class SalesInvoiceCreated extends InvoiceState {
  final SalesInvoice invoice;

  const SalesInvoiceCreated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class SalesInvoiceUpdated extends InvoiceState {
  final SalesInvoice invoice;

  const SalesInvoiceUpdated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class SalesInvoiceDeleted extends InvoiceState {
  const SalesInvoiceDeleted();
}

// Purchase Invoice States
class PurchaseInvoicesLoaded extends InvoiceState {
  final List<PurchaseInvoice> invoices;

  const PurchaseInvoicesLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

class FilteredPurchaseInvoicesLoaded extends InvoiceState {
  final List<PurchaseInvoice> invoices;
  final DateFilter filter;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilteredPurchaseInvoicesLoaded(this.invoices, this.filter, {this.startDate, this.endDate});

  @override
  List<Object?> get props => [invoices, filter, startDate, endDate];
}

class PurchaseInvoiceLoaded extends InvoiceState {
  final PurchaseInvoice invoice;

  const PurchaseInvoiceLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class PurchaseInvoiceCreated extends InvoiceState {
  final PurchaseInvoice invoice;

  const PurchaseInvoiceCreated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class PurchaseInvoiceUpdated extends InvoiceState {
  final PurchaseInvoice invoice;

  const PurchaseInvoiceUpdated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class PurchaseInvoiceDeleted extends InvoiceState {
  const PurchaseInvoiceDeleted();
}

// Error State
class InvoiceError extends InvoiceState {
  final String message;

  const InvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}

// Real-time form update state - triggers UI rebuild without saving to database
class InvoiceFormUpdated extends InvoiceState {
  final String? updateType;

  const InvoiceFormUpdated({this.updateType});

  @override
  List<Object?> get props => [updateType];
}

// New Filtered State
class InvoiceFiltered extends InvoiceState {
  final List<SalesInvoice> salesInvoices;
  final List<PurchaseInvoice> purchaseInvoices;
  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final double totalAmount;

  const InvoiceFiltered({
    required this.salesInvoices,
    required this.purchaseInvoices,
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [
    salesInvoices,
    purchaseInvoices,
    totalCount,
    paidCount,
    pendingCount,
    totalAmount,
  ];
}
