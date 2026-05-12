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

  const SuppliersLoaded(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
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
