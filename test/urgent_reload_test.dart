import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds every request open until the test finishes it, so that tests control
/// exactly which requests are in flight.
class FakeGatedHttpService extends CesiumHttpService {
  final List<int> requestedPages = [];
  final List<Completer<Response>> _pending = [];

  @override
  void reset() {
    requestedPages.clear();
    _pending.clear();
  }

  @override
  Future<Response> get(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) {
    final page = params?['page'] as int;
    requestedPages.add(page);
    final completer = Completer<Response>();
    _pending.add(completer);
    return completer.future.then(
      (_) => Response(requestOptions: RequestOptions(path: url), data: page),
    );
  }

  /// Finish the request at `index` in the order requests were made.
  Future<void> finish(int index) async {
    _pending[index].complete(
      Response(requestOptions: RequestOptions(path: '')),
    );
    await pumpEventQueue();
  }
}

const debounce = Duration(milliseconds: 20);

Future<void> waitForDebounce() =>
    Future.delayed(debounce * 3).then((_) => pumpEventQueue());

PaginatedHttpResource<int> paginatedResource({
  Iterable<Listenable> dependecies = const [],
  Iterable<Listenable> urgentDependecies = const [],
  Duration? debounceDuration,
}) {
  return PaginatedHttpResource<int>(
    (_) => 'https://example.com',
    (data) => data as int,
    (page) => {'page': page},
    dependecies: dependecies,
    urgentDependecies: urgentDependecies,
    debounceDuration: debounceDuration,
  );
}

void main() {
  setUpAll(() {
    cesiumHttpServiceProvider.override(() => FakeGatedHttpService());
  });

  tearDown(() {
    cesiumHttpServiceProvider.reset();
  });

  FakeGatedHttpService service() =>
      cesiumHttpServiceProvider.inject() as FakeGatedHttpService;

  test('urgentDependecies reload an HttpResource without debounce', () async {
    final httpService = service();
    final urgent = ValueNotifier(0);
    final resource = HttpResource<int>(
      () => 'https://example.com',
      (data) => data as int,
      queryParametersBuilder: () => {'page': 1},
      urgentDependecies: [urgent],
      debounceDuration: const Duration(hours: 1),
    );

    urgent.value++;

    expect(httpService.requestedPages, [1, 1]);
    resource.dispose();
    urgent.value++;
    expect(httpService.requestedPages, [1, 1]);
    urgent.dispose();
  });

  test('urgentDependecies reset a PaginatedHttpResource', () async {
    final httpService = service();
    final urgent = ValueNotifier(0);
    final resource = paginatedResource(
      urgentDependecies: [urgent],
      debounceDuration: const Duration(hours: 1),
    );
    await httpService.finish(0);

    urgent.value++;

    expect(httpService.requestedPages, [1, 1]);
    resource.dispose();
    urgent.dispose();
  });

  test('urgentReload cancels a pending debounced reload', () async {
    final httpService = service();
    final resource = paginatedResource(debounceDuration: debounce);
    await httpService.finish(0);

    resource.reload();
    resource.urgentReload();
    await httpService.finish(1);
    await waitForDebounce();

    expect(httpService.requestedPages, [1, 1]);
    expect(resource.result, [1]);
    resource.dispose();
  });

  test('reload replaces accumulated pages', () async {
    final httpService = service();
    final resource = paginatedResource();
    await httpService.finish(0);
    resource.loadMore();
    await httpService.finish(1);
    expect(resource.result, [1, 2]);

    resource.reload();
    // The old pages stay visible until the new first page arrives
    expect(resource.result, [1, 2]);
    await httpService.finish(2);

    expect(resource.result, [1]);
    resource.dispose();
  });

  test('urgentReload replaces accumulated pages', () async {
    final httpService = service();
    final resource = paginatedResource();
    await httpService.finish(0);
    resource.loadMore();
    await httpService.finish(1);

    resource.urgentReload();
    await httpService.finish(2);

    expect(resource.result, [1]);
    resource.dispose();
  });

  test('a cancelled request does not skip a page', () async {
    final httpService = service();
    final resource = paginatedResource();

    resource.urgentReload();
    await httpService.finish(0);
    await httpService.finish(1);
    expect(resource.result, [1]);

    resource.loadMore();
    expect(httpService.requestedPages, [1, 1, 2]);
    await httpService.finish(2);

    expect(resource.result, [1, 2]);
    resource.dispose();
  });

  test('repeated loadMore requests the same page once', () async {
    final httpService = service();
    final resource = paginatedResource();
    await httpService.finish(0);

    resource.loadMore();
    resource.loadMore();
    await httpService.finish(1);
    await httpService.finish(2);
    resource.loadMore();

    expect(httpService.requestedPages, [1, 2, 2, 3]);
    resource.dispose();
  });

  test('a request in flight during a debounced reload does not move the page', () async {
    final httpService = service();
    final resource = paginatedResource(debounceDuration: debounce);
    await httpService.finish(0);
    resource.runRequest(useDebounce: false);
    expect(httpService.requestedPages, [1, 2]);

    resource.reload();
    await httpService.finish(1);
    await waitForDebounce();
    expect(httpService.requestedPages, [1, 2, 1]);
    await httpService.finish(2);

    expect(resource.result, [1]);
    resource.dispose();
  });
}
