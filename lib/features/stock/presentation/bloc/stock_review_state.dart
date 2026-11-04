part of 'stock_review_cubit.dart';

abstract class StockReviewState extends Equatable {
  const StockReviewState();

  @override
  List<Object?> get props => [];
}

class StockReviewInitial extends StockReviewState {
  const StockReviewInitial();
}

class StockReviewLoading extends StockReviewState {
  const StockReviewLoading();
}

class StockReviewLoaded extends StockReviewState {
  final List<StockReviewItem> items;
  final bool hasMore;
  final bool isLoadingMore;

  const StockReviewLoaded(
    this.items, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [items, hasMore, isLoadingMore];
}

class StockReviewError extends StockReviewState {
  final String message;

  const StockReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
