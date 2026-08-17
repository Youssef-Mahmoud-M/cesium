import 'dart:async';
import 'dart:math' as math;

import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Base class for HTTP-backed resources.
///
/// Extends `FutureResource<T>` and provides progress reporting via
/// `progressNotifier`, automatic dependency listening, and helpers to
/// make HTTP requests using the shared `CesiumHttpService`.
abstract class HttpResourceBase<T> extends FutureResource<T> {
  /// Progress notifier that reports a value between `0` and `1`.
  final ValueNotifier<double> progressNotifier = ValueNotifier(0);

  /// The shared HTTP service used to perform requests.
  final CesiumHttpService httpService = cesiumHttpServiceProvider.inject();

  final Iterable<Listenable> _dependecies;

  /// Optional duration to debounce repeated `runRequest` calls.
  final Duration? debounceDuration;

  /// Optional max retry attempts with exponential backoff
  final int maxRetryAttempts;
  Timer? _debounceTimer;

  /// Headers applied to each HTTP request made by this resource.
  Map<String, dynamic> headers;

  /// Create a base HTTP resource.
  ///
  /// `dependecies` are listened to and will trigger reloads when they
  /// notify. `perserveResults` controls whether previous results are
  /// kept while a new request runs. `maxRetryAttempts` is the max
  /// number of times it will reattempt the request
  HttpResourceBase({
    Iterable<Listenable> dependecies = const [],
    this.debounceDuration,
    this.headers = const {},
    bool perserveResults = false,
    this.maxRetryAttempts = 0,
  }) : _dependecies = dependecies,
       super(null, perserveResults) {
    runRequest(useDebounce: false);
    for (var dependency in _dependecies) {
      dependency.addListener(reload);
    }
    retryActionOnError = (error, attempt) {
      if (attempt <= maxRetryAttempts) {
        final double delaySeconds = 3 * math.pow(1.5, attempt - 1).toDouble();
        final int delay = delaySeconds.ceil();

        return Future.delayed(Duration(seconds: delay), () => makeRequest());
      }
      return null;
    };
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

  /// Trigger a reload of the resource, honoring debounce settings.
  void reload() {
    runRequest();
  }

  /// Trigger a request immediately or after the configured debounce
  /// duration.
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

  /// Make an HTTP GET request using the shared `CesiumHttpService` and
  /// update the `progressNotifier` while downloading.
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

  /// Subclasses implement this to perform the concrete request and
  /// convert the response into the resource value of type `T`.
  Future<T> makeRequest();

  /// Like `pipe`, but provides a progress value to the `loading` builder.
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
