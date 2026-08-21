import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';

/// Global provider for the shared `CesiumHttpService`.
final cesiumHttpServiceProvider = ServiceProvider(() => CesiumHttpService());

/// Simple HTTP service built on top of `dio` exposed as a `CesiumService`.
class CesiumHttpService extends CesiumService {
  Dio _dio;
  Dio Function()? _dioBuilder;

  /// CesiumHttpService constructor, if `_dioBuilder` is provided,
  /// it will be used instead of the default Dio constructor
  CesiumHttpService({Dio Function()? dioBuilder})
    : _dioBuilder = dioBuilder,
      _dio = dioBuilder == null ? Dio() : dioBuilder();

  /// Access or replace the underlying `BaseOptions` used by `dio`.
  BaseOptions get baseOptions => _dio.options;
  set baseOptions(BaseOptions newOptions) {
    _dio.options = newOptions;
  }

  /// Sets the builder used to build the dio instance
  /// Immediately rebuilds the dio instance
  void setDioBuilder(Dio Function() builder) {
    _dioBuilder = builder;
    reset();
  }

  /// Interceptors applied to the underlying `dio` client.
  Interceptors get interceptors => _dio.interceptors;

  /// Perform an HTTP GET request.
  Future<Response> get(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return await _dio.get(
      url,
      data: data,
      options: options,
      queryParameters: params,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform an HTTP POST request.
  Future<Response> post(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
  }) async {
    return await _dio.post(
      url,
      data: data,
      options: options,
      queryParameters: params,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
    );
  }

  /// Perform an HTTP PUT request.
  Future<Response> put(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
  }) async {
    return await _dio.put(
      url,
      data: data,
      options: options,
      queryParameters: params,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
    );
  }

  /// Perform an HTTP PATCH request.
  Future<Response> patch(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
  }) async {
    return await _dio.patch(
      url,
      data: data,
      options: options,
      queryParameters: params,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
    );
  }

  /// Perform an HTTP DELETE request.
  Future<Response> delete(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete(
      url,
      data: data,
      options: options,
      queryParameters: params,
      cancelToken: cancelToken,
    );
  }

  @override
  void reset() {
    _dio.close();
    _dio = _dioBuilder == null ? Dio() : _dioBuilder!();
    notifyListeners();
  }
}
