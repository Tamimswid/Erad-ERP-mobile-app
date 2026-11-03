import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class AppPaginationSliverList extends StatelessWidget {
  const AppPaginationSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.separator = const SizedBox(height: 12),
    this.bottomSpace = 100,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final EdgeInsetsGeometry padding;
  final Widget separator;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: itemCount + 1,
        itemBuilder: (context, index) {
          if (index >= itemCount) {
            return AppPaginationFooter(
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              onLoadMore: onLoadMore,
              bottomSpace: bottomSpace,
            );
          }
          return itemBuilder(context, index);
        },
        separatorBuilder: (context, index) => separator,
      ),
    );
  }
}

class AppPaginationGrid extends StatefulWidget {
  const AppPaginationGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.all(16),
    this.bottomSpace = 24,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final EdgeInsetsGeometry padding;
  final double bottomSpace;

  @override
  State<AppPaginationGrid> createState() => _AppPaginationGridState();
}

class _AppPaginationGridState extends State<AppPaginationGrid> {
  static const double _loadThreshold = 300;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  @override
  void didUpdateWidget(covariant AppPaginationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  void _maybeLoadMore() {
    if (!mounted || !widget.hasMore || widget.isLoadingMore) return;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent - position.pixels <= _loadThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_maybeLoadMore);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverGrid.builder(
            itemCount: widget.itemCount,
            gridDelegate: widget.gridDelegate,
            itemBuilder: widget.itemBuilder,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.bottomSpace),
            child: SizedBox(
              height: 48,
              child: widget.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: sc.CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class AppPaginationFooter extends StatefulWidget {
  const AppPaginationFooter({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.bottomSpace = 100,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final double bottomSpace;

  @override
  State<AppPaginationFooter> createState() => _AppPaginationFooterState();
}

class _AppPaginationFooterState extends State<AppPaginationFooter> {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant AppPaginationFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleLoad();
  }

  void _scheduleLoad() {
    if (_scheduled || !widget.hasMore || widget.isLoadingMore) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !widget.hasMore || widget.isLoadingMore) return;
      widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoad();

    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: widget.bottomSpace),
      child: SizedBox(
        height: 48,
        child: widget.isLoadingMore
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: sc.CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
