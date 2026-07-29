part of 'party_invoice_cubit.dart';

abstract class PartyInvoiceState extends Equatable {
  const PartyInvoiceState();

  @override
  List<Object?> get props => [];
}

class PartyInvoiceInitial extends PartyInvoiceState {
  const PartyInvoiceInitial();
}

class PartyInvoiceLoading extends PartyInvoiceState {
  const PartyInvoiceLoading();
}

class PartyInvoiceLoaded extends PartyInvoiceState {
  final List<dynamic> invoices;
  final int totalCount;

  const PartyInvoiceLoaded({
    required this.invoices,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [invoices, totalCount];
}

class PartyInvoiceError extends PartyInvoiceState {
  final String message;

  const PartyInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
