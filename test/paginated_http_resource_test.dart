import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePaginatedHttpService extends CesiumHttpService {
  int? lastRequestPage;

  @override
  void reset() {
    lastRequestPage = null;
  }

  @override
  Future<Response> get(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    lastRequestPage = int.parse(params?['page'].toString() ?? "0");
    int startingItem = (lastRequestPage! - 1) * 12 + 1;
    return Response(
      requestOptions: RequestOptions(path: url),
      data: {
        "total": 25,
        "items": List.generate(
          12,
          (index) => {"title": "Item ${index + startingItem}"},
        ),
      },
    );
  }
}

void main() {
  setUpAll(() {
    cesiumHttpServiceProvider.override(() => FakePaginatedHttpService());
  });

  tearDown(() {
    cesiumHttpServiceProvider.reset();
  });

  test('paginated http resource runs with page 1 on first request', () async {
    final httpService =
        cesiumHttpServiceProvider.inject() as FakePaginatedHttpService;
    PaginatedHttpResource<Map<String, dynamic>> httpResource =
        PaginatedHttpResource(
          (_) => 'https://example.com',
          (data) => data,
          (page) => {'page': page},
        );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading) completer.complete();
    });

    await completer.future;

    expect(httpService.lastRequestPage, 1);
    httpResource.dispose();
  });

  test(
    'paginated http resource runs with custom first page on first request',
    () async {
      final httpService =
          cesiumHttpServiceProvider.inject() as FakePaginatedHttpService;
      PaginatedHttpResource<Map<String, dynamic>> httpResource =
          PaginatedHttpResource(
            (_) => 'https://example.com',
            (data) => data,
            (page) => {'page': page},
            startPage: 3,
          );

      final completer = Completer<void>();
      httpResource.addListener(() {
        if (!httpResource.isLoading) completer.complete();
      });

      await completer.future;

      expect(httpService.lastRequestPage, 3);
      httpResource.dispose();
    },
  );

  test('paginated http resource increments page in loadmore', () async {
    final httpService =
        cesiumHttpServiceProvider.inject() as FakePaginatedHttpService;
    PaginatedHttpResource<Map<String, dynamic>> httpResource =
        PaginatedHttpResource(
          (_) => 'https://example.com',
          (data) => data,
          (page) => {'page': page},
        );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading && (httpService.lastRequestPage ?? 0) > 1) {
        completer.complete();
      } else if (!httpResource.isLoading && httpService.lastRequestPage == 1) {
        httpResource.loadMore();
      }
    });

    await completer.future;

    expect(httpService.lastRequestPage, 2);
    httpResource.dispose();
  });

  test('paginated http resource resets page when dependency changes', () async {
    ValueNotifier<int> testValue = ValueNotifier(0);
    final httpService =
        cesiumHttpServiceProvider.inject() as FakePaginatedHttpService;
    PaginatedHttpResource<Map<String, dynamic>> httpResource =
        PaginatedHttpResource(
          (_) => 'https://example.com',
          (data) => data,
          (page) => {'page': page},
          dependecies: [testValue],
        );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading &&
          (httpService.lastRequestPage ?? 0) > 1 &&
          testValue.value == 0) {
        testValue.value++;
      } else if (!httpResource.isLoading &&
          httpService.lastRequestPage == 1 &&
          testValue.value == 0) {
        httpResource.loadMore();
      } else if (!httpResource.isLoading &&
          httpService.lastRequestPage == 1 &&
          testValue.value == 1) {
        completer.complete();
      }
    });

    await completer.future;

    expect(httpService.lastRequestPage, 1);
    expect(testValue.value, 1);
    httpResource.dispose();
    testValue.dispose();
  });

  test('paginated http resource does not exceed maxPages', () async {
    final httpService =
        cesiumHttpServiceProvider.inject() as FakePaginatedHttpService;
    PaginatedHttpResource<Map<String, dynamic>> httpResource =
        PaginatedHttpResource(
          (_) => 'https://example.com',
          (data) => data,
          (page) => {'page': page},
          getMaxPages: (data) {
            return (int.parse(data['total'].toString()) / 12).ceil();
          },
        );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading) {
        if (httpService.lastRequestPage != null) {
          if (httpService.lastRequestPage! < 4) {
            int lastRequestPage = httpService.lastRequestPage!;
            httpResource.loadMore();
            if (lastRequestPage == 3) completer.complete();
          }
        }
      }
    });

    await completer.future;

    expect(httpService.lastRequestPage, 3);
    httpResource.dispose();
  });
}
