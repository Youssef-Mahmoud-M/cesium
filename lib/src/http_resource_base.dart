import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

abstract class HttpResourceBase<T> extends FutureResource<T> {
  final ValueNotifier<double> progressNotifier = ValueNotifier(0);
  final CesiumHttpService httpService = cesiumHttpServiceProvider.inject();
  final Iterable<Listenable> _dependecies;
  final Duration? debounceDuration;
  Timer? _debounceTimer;
  Map<String, dynamic> headers;

  HttpResourceBase({
    Iterable<Listenable> dependecies = const [],
    this.debounceDuration,
    this.headers = const {},
    bool perserveResults = false,
  }) : _dependecies = dependecies,
       super(null, perserveResults) {
    runRequest(useDebounce: false);
    for (var dependency in _dependecies) {
      dependency.addListener(reload);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var dependency in _dependecies) {
      dependency.removeListener(reload);
    }
    _debounceTimer?.cancel();
    progressNotifier.dispose();
  }

  void reload() {
    runRequest();
  }

  void runRequest({bool useDebounce = true}) {
    if (!useDebounce || debounceDuration == null) {
      progressNotifier.value = 0;
      runNewFuture(() => makeRequest());
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration!, () {
      runRequest(useDebounce: false);
    });
  }

  Future<Response> makeHttpRequest(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    final resp = await httpService.get(
      url,
      options: Options(headers: headers),
      params: queryParameters,
      onReceiveProgress: (received, total) {
        progressNotifier.value = received / total;
      },
    );
    progressNotifier.value = 1;
    return resp;
  }

  Future<T> makeRequest();

  Widget pipeProgress({
    required Widget Function(BuildContext context, double progress) loading,
    required Widget Function(BuildContext, Object) error,
    required Widget Function(BuildContext, T value) value,
  }) {
    return super.pipe(
      loading: (context) => ValueListenableBuilder(
        valueListenable: progressNotifier,
        builder: (BuildContext context, value, Widget? child) =>
            loading(context, value),
      ),
      error: error,
      value: value,
    );
  }
}
