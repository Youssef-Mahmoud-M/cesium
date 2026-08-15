import 'dart:async';

import 'package:cesium/src/http_resource_base.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class PaginatedHttpResource<T> extends HttpResourceBase<List<T>> {
  final int Function(T)? getMaxPages;
  final String Function() urlBuilder;
  final int _beginningPage;
  final T Function(dynamic data) transform;
  final Map<String, dynamic> Function(int page) queryParamatersBuilder;
  int _page;
  bool get reachedEnd {
    if (getMaxPages == null || result?.firstOrNull == null) return false;
    final maxPages = getMaxPages!(result!.first);
    return _page == maxPages + 1;
  }

  PaginatedHttpResource(
    this.urlBuilder,
    this.transform,
    this.queryParamatersBuilder, {
    super.dependecies = const [],
    super.debounceDuration,
    super.headers = const {},
    this.getMaxPages,
    int startPage = 1,
  }) : _page = startPage,
       _beginningPage = startPage,
       super(perserveResults: true);

  void loadMore() {
    if (getMaxPages != null && result?.isNotEmpty == true) {
      int maxPages = getMaxPages!(result!.first);
      if (_page > maxPages) {
        return;
      }
    }
    runRequest();
  }

  @override
  void reload() {
    _page = _beginningPage;
    super.reload();
  }

  @override
  Future<List<T>> makeRequest() async {
    final response = await makeHttpRequest(
      urlBuilder(),
      queryParamatersBuilder(_page),
    );

    final newResult = [
      if (result != null) ...result!,
      transform(response.data),
    ];
    _page++;
    return newResult;
  }

  Widget pipePaginated<T2>({
    required Widget Function(BuildContext context, double progress) loading,
    required Widget Function(BuildContext, Object) error,
    required Widget Function(BuildContext, T2 value, int index) itemBuilder,
    required List<T2> Function(T item) getItems,
    Widget Function(BuildContext, double progress)? inlineLoading,
    Widget Function(BuildContext, Object)? inlineError,
    Widget Function(BuildContext)? inlineEnd,
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
    return super.pipeProgress(
      loading: loading,
      error: error,
      value: (context, val) {
        final items = val.expand((e) => getItems(e));
        final hasInlineInfo =
            (value.error != null && inlineError != null) ||
            (value.isLoading && inlineLoading != null);
        final itemCount =
            items.length +
            (hasInlineInfo ? 1 : 0) +
            (reachedEnd && inlineEnd != null ? 1 : 0);

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
            if (hasInlineInfo && index == items.length) {
              if (value.isLoading && inlineLoading != null) {
                return ValueListenableBuilder(
                  valueListenable: progressNotifier,
                  builder: (context, progress, _) =>
                      inlineLoading(context, progress),
                );
              }
              return inlineError!(context, value.error!);
            }
            return inlineEnd!(context);
          },
        );
      },
    );
  }
}
