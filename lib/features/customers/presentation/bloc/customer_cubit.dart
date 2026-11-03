import 'package:erad/features/customers/data/models/customer.dart';
import 'package:erad/features/customers/data/repositories/customer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  static const int pageSize = 10;

  final CustomerRepository customerRepository;

  CustomerCubit({required this.customerRepository}) : super(CustomerInitial());

  final List<CustomerModel> _customers = [];
  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _pagedMode = false;
  String _searchQuery = '';

  /// Loads the full customer list (used by invoice pickers and reports).
  Future<void> getCustomers() async {
    _pagedMode = false;
    _searchQuery = '';
    final requestId = ++_requestId;
    if (!isClosed) emit(CustomerLoading());

    final result = await customerRepository.getCustomers();
    if (isClosed || requestId != _requestId) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomerLoaded(customers, hasMore: false)),
    );
  }

  /// Loads the first page for the paginated customers page.
  Future<void> loadFirstPage({bool showLoading = true}) async {
    _pagedMode = true;
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _customers.clear();

    if (showLoading && !isClosed) emit(CustomerLoading());

    final result = await customerRepository.getCustomersPage(
      offset: 0,
      limit: pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (isClosed || requestId != _requestId) return;

    result.fold((failure) => emit(CustomerError(failure.message)), (page) {
      _customers.addAll(page.items);
      _offset = page.items.length;
      _hasMore = page.hasMore;
      _emitLoaded();
    });
  }

  Future<void> loadMore() async {
    if (!_pagedMode || isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await customerRepository.getCustomersPage(
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
        _customers.addAll(page.items);
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
      CustomerLoaded(
        List<CustomerModel>.unmodifiable(_customers),
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  Future<void> searchCustomers(String query) async {
    _searchQuery = query.trim();
    await loadFirstPage(showLoading: false);
  }

  Future<void> createCustomer(CustomerModel customer) async {
    if (isClosed) return;
    final result = await customerRepository.createCustomer(customer);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => _refreshAfterMutation(),
    );
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    if (isClosed) return;
    final result = await customerRepository.updateCustomer(customer);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => _refreshAfterMutation(),
    );
  }

  Future<void> deleteCustomer(String id) async {
    if (isClosed) return;
    final result = await customerRepository.deleteCustomer(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => _refreshAfterMutation(),
    );
  }

  void _refreshAfterMutation() {
    if (_pagedMode) {
      loadFirstPage(showLoading: false);
    } else {
      getCustomers();
    }
  }

  void clearError() {
    if (isClosed) return;
    if (state is CustomerError) {
      emit(CustomerInitial());
    }
  }
}
