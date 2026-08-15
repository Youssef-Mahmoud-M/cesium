import 'dart:async';

import 'package:cesium/src/http_resource_base.dart';

/// Simple HTTP-backed resource that fetches a single value of type `T`.
///
/// Provide a `urlBuilder` to construct the request URL and a `transform`
/// function to convert the raw response body into the desired type.
class HttpResource<T> extends HttpResourceBase<T> {
  /// Function that returns the request URL for the current load.
  final String Function() urlBuilder;

  /// Transform the raw response body into the desired `T` value.
  final T Function(dynamic data) transform;

  /// Optionally build query parameters for each request.
  final Map<String, dynamic> Function()? queryParametersBuilder;

  /// Create an `HttpResource`.
  ///
  /// `urlBuilder` should return the request URL and `transform` converts the
  /// response body into `T`.
  HttpResource(
    this.urlBuilder,
    this.transform, {
    this.queryParametersBuilder,
    super.dependecies = const [],
    super.debounceDuration,
    super.headers = const {},
  });

  @override
  Future<T> makeRequest() async {
    return transform(
      (await makeHttpRequest(
        urlBuilder(),
        queryParametersBuilder == null ? {} : queryParametersBuilder!(),
      )).data,
    );
  }
}
