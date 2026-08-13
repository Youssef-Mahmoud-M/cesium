import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'future_resource.dart';

class PaginatedHttpResource<T> extends FutureResource<List<T>> {
  final Dio _dio = Dio();
  final Iterable<Listenable> _dependecies;
  final String Function(int page) urlBuilder;
  final int _beginningPage;
  final Duration? debounceDuration;
  final T Function(dynamic data) transform;
  final int Function(T)? getMaxPages;
  int _page;
  Timer? _debounceTimer;
  Map<String, dynamic> headers;

  PaginatedHttpResource(
    this.urlBuilder,
    this.transform, {
    Iterable<Listenable> dependecies = const [],
    this.debounceDuration,
    int page = 1,
    this.getMaxPages,
    this.headers = const {},
  }) : _dependecies = dependecies,
       _page = page,
       _beginningPage = page,
       super(null, true) {
    _runRequest(useDebounce: false);
    for (var dependency in _dependecies) {
      dependency.addListener(_onDependencyChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dio.close();
    for (var dependency in _dependecies) {
      dependency.removeListener(_onDependencyChanged);
    }
    _debounceTimer?.cancel();
  }

  void loadMore() {
    if (getMaxPages != null && result?.isNotEmpty == true) {
      int maxPages = getMaxPages!(result!.first);
      if (_page > maxPages) {
        return;
      }
    }
    _runRequest(resetPage: false);
  }

  void reload() {
    _runRequest();
  }

  void _onDependencyChanged() {
    _runRequest();
  }

  void _runRequest({bool useDebounce = true, bool resetPage = true}) {
    if (!useDebounce || debounceDuration == null) {
      if (resetPage) {
        _page = _beginningPage;
      }
      runNewFuture(() => _makeRequest(urlBuilder(_page)));
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration!, () {
      _runRequest(useDebounce: false);
    });
  }

  Future<List<T>> _makeRequest(String url) async {
    final response = await _dio.get(url, options: Options(headers: headers));

    final newResult = [
      if (result != null) ...result!,
      transform(response.data),
    ];
    _page++;
    return newResult;
  }

  Widget pipePaginated<T2>({
    required Widget Function(BuildContext context) loading,
    required Widget Function(BuildContext, Object) error,
    required Widget Function(BuildContext, T2 value, int index) itemBuilder,
    required List<T2> Function(T item) getItems,
    Widget Function(BuildContext)? inlineLoading,
    Widget Function(BuildContext, Object)? inlineError,
    bool isRow = false,

    Axis? scrollDirection,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    Widget? prototypeItem,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return super.pipe(
      loading: loading,
      error: error,
      value: (context, val) {
        final items = val.expand((e) => getItems(e));
        final hasInlineExtra =
            (value.error != null && inlineError != null) ||
            (value.isLoading && inlineLoading != null);
        final itemCount = items.length + (hasInlineExtra ? 1 : 0);

        return ListView.builder(
          scrollDirection:
              scrollDirection ?? (isRow ? Axis.horizontal : Axis.vertical),
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          prototypeItem: prototypeItem,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < items.length) {
              return itemBuilder(context, items.elementAt(index), index);
            }
            if (value.isLoading && inlineLoading != null) {
              return inlineLoading(context);
            }
            return inlineError!(context, value.error!);
          },
        );
      },
    );
  }
}
