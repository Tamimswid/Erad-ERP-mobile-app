import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/supplier.dart';
import '../../data/repositories/supplier_repository.dart';

part 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  static const int pageSize = 10;

  final SupplierRepository supplierRepository;
  final DataChangeNotifier _dataChanges;
  late int _dataChangeVersion;

  SupplierCubit({
    required this.supplierRepository,
    required DataChangeNotifier dataChanges,
  }) : _dataChanges = dataChanges,
       super(SupplierInitial()) {
    _dataChangeVersion = _dataChanges.versionOf(DataDomain.suppliers);
    _dataChanges.addListener(_handleDataChange);
  }

  final List<SupplierModel> _suppliers = [];
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  bool _pagedMode = false;
  String _searchQuery = '';

  void _handleDataChange() {
    if (isClosed) return;
    final version = _dataChanges.versionOf(DataDomain.suppliers);
    if (version == _dataChangeVersion) return;
    _dataChangeVersion = version;
    if (_pagedMode) {
      loadFirstPage(showLoading: false);
    } else {
      getSuppliers(showLoading: false);
    }
  }

  /// Loads the full supplier list (used by invoice pickers and reports).
  Future<void> getSuppliers({bool showLoading = true}) async {
    _pagedMode = false;
    _searchQuery = '';
    final requestId = ++_requestId;
    if (showLoading && !isClosed) emit(SupplierLoading());

    final result = await supplierRepository.getSuppliers();
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) {
        emit(SupplierError(failure.message));
        if (_hasLoaded) _emitLoaded();
      },
      (suppliers) {
        _suppliers
          ..clear()
          ..addAll(suppliers);
        _hasMore = false;
        _hasLoaded = true;
        emit(SuppliersLoaded(suppliers, hasMore: false));
      },
    );
  }

  /// Loads the first page for the paginated suppliers page.
  Future<void> loadFirstPage({bool showLoading = true}) async {
    _pagedMode = true;
    final requestId = ++_requestId;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;

    if (showLoading && !isClosed) emit(SupplierLoading());

    final result = await supplierRepository.getSuppliersPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(SupplierError(failure.message));
        if (_hasLoaded) _emitLoaded();
      },
      (page) {
        _suppliers
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;
        _hasLoaded = true;
        _emitLoaded();
      },
    );
  }

  Future<void> loadMore() async {
    if (!_pagedMode || isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await supplierRepository.getSuppliersPage(
      offset: _offset,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold(
      (_) {
        _isLoadingMore = false;
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _suppliers.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      SuppliersLoaded(
        List<SupplierModel>.unmodifiable(_suppliers),
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> searchSuppliers(String query) async {
    _searchQuery = query.trim();
    await loadFirstPage(showLoading: false);
  }

  Future<void> createSupplier(SupplierModel supplier) async {
    if (isClosed) return;
    final result = await supplierRepository.createSupplier(supplier);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) => _notifyChanged(),
    );
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (isClosed) return;
    final result = await supplierRepository.updateSupplier(supplier);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) => _notifyChanged(),
    );
  }

  Future<void> deleteSupplier(String id) async {
    if (isClosed) return;
    final result = await supplierRepository.deleteSupplier(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) => _notifyChanged(),
    );
  }

  void _notifyChanged() {
    _dataChanges.notifyChangedAll([
      DataDomain.suppliers,
      DataDomain.supplierDebts,
    ]);
  }

  void clearError() {
    if (isClosed) return;
    if (state is SupplierError) {
      emit(SupplierInitial());
    }
  }

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }
}
