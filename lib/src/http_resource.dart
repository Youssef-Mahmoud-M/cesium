import 'dart:async';

import 'package:cesium/src/http_resource_base.dart';

class HttpResource<T> extends HttpResourceBase<T> {
  final String Function() urlBuilder;
  final T Function(dynamic data) transform;
  final Map<String, dynamic> Function()? queryParametersBuilder;
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
