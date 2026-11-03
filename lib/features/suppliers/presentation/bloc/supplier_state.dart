part of 'supplier_cubit.dart';

abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<SupplierModel> suppliers;
  final bool hasMore;
  final bool isLoadingMore;

  const SuppliersLoaded(
    this.suppliers, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [suppliers, hasMore, isLoadingMore];
}

class SupplierSingleLoaded extends SupplierState {
  final SupplierModel supplier;

  const SupplierSingleLoaded(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class SupplierSuccess extends SupplierState {
  final String message;

  const SupplierSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError(this.message);

  @override
  List<Object?> get props => [message];
}
