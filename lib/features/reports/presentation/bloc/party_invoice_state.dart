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
  final bool hasMore;
  final bool isLoadingMore;

  const PartyInvoiceLoaded({
    required this.invoices,
    required this.totalCount,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [invoices, totalCount, hasMore, isLoadingMore];
}

class PartyInvoiceError extends PartyInvoiceState {
  final String message;

  const PartyInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
