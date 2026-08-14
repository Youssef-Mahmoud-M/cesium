import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHttpService extends CesiumHttpService {
  int count = 0;
  bool shouldThrow = false;

  @override
  void reset() {
    count = 0;
    shouldThrow = false;
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
    if (shouldThrow) throw "Error";
    count++;
    return Response(
      requestOptions: RequestOptions(path: url),
      data: [
        {"title": "Black Coffee"},
        {"title": "Latte"},
      ],
    );
  }
}

void main() {
  setUpAll(() {
    cesiumHttpServiceProvider.override(() => FakeHttpService());
  });

  tearDown(() {
    cesiumHttpServiceProvider.reset();
  });

  test('Http resource makes initial http request', () async {
    final httpResource = HttpResource<List<String>>(
      () => "https://api.sampleapis.com/coffee/hot",
      (data) {
        return (data as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)["title"].toString())
            .toList();
      },
    );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading) completer.complete();
    });

    await completer.future;

    expect(httpResource.result, equals(['Black Coffee', 'Latte']));
    httpResource.dispose();
  });

  test('Http resource reports when error is thrown', () async {
    final FakeHttpService httpService =
        cesiumHttpServiceProvider.inject() as FakeHttpService;
    httpService.shouldThrow = true;
    final httpResource = HttpResource<List<String>>(
      () => "https://api.sampleapis.com/coffee/hot",
      (data) {
        return (data as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)["title"].toString())
            .toList();
      },
    );

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading) completer.complete();
    });

    await completer.future;

    expect(httpResource.error, equals("Error"));
    httpResource.dispose();
  });

  test('Http resource reruns request when dependency changes', () async {
    ValueNotifier<int> testNotifier = ValueNotifier(0);
    final httpResource = HttpResource<List<String>>(
      () => "https://api.sampleapis.com/coffee/hot",
      (data) {
        return (data as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)["title"].toString())
            .toList();
      },
      dependecies: [testNotifier],
    );

    final FakeHttpService httpService =
        cesiumHttpServiceProvider.inject() as FakeHttpService;

    final completer = Completer<void>();
    httpResource.addListener(() {
      if (!httpResource.isLoading && httpService.count == 1) {
        testNotifier.value++;
      }
      if (!httpResource.isLoading && httpService.count == 2) {
        completer.complete();
      }
    });

    await completer.future;

    expect(httpResource.result, equals(['Black Coffee', 'Latte']));
    expect(httpService.count, equals(2));

    httpResource.dispose();
    testNotifier.dispose();
  });
}
