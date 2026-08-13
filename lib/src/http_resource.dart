import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'future_resource.dart';

class HttpResource<T> extends FutureResource<T> {
  final Dio _dio = Dio();
  final Iterable<Listenable> _dependecies;
  final String Function() urlBuilder;
  final Duration? debounceDuration;
  final T Function(dynamic data) transform;
  Timer? _debounceTimer;
  Map<String, dynamic> headers;

  HttpResource(
    this.urlBuilder,
    this.transform, {
    Iterable<Listenable> dependecies = const [],
    this.debounceDuration,
    this.headers = const {},
  }) : _dependecies = dependecies,
       super(null) {
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

  void reload() {
    _runRequest();
  }

  void _onDependencyChanged() {
    _runRequest();
  }

  void _runRequest({bool useDebounce = true}) {
    if (!useDebounce || debounceDuration == null) {
      runNewFuture(() => _makeRequest(urlBuilder()));
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration!, () {
      _runRequest(useDebounce: false);
    });
  }

  Future<T> _makeRequest(String url) async {
    final response = await _dio.get(url, options: Options(headers: headers));

    return transform(response.data);
  }
}
