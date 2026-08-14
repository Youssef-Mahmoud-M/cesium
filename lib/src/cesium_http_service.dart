import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';

final cesiumHttpServiceProvider = ServiceProvider(() => CesiumHttpService());

class CesiumHttpService extends CesiumService {
  Dio _dio = Dio();
  BaseOptions get baseOptions => _dio.options;
  set baseOptions(BaseOptions newOptions) {
    _dio.options = newOptions;
  }

  Interceptors get interceptors => _dio.interceptors;

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
    _dio = Dio();
    notifyListeners();
  }
}
