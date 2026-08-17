// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';

class FakeRetryHttpService extends CesiumHttpService {
  int _attempt = 0;
  @override
  void reset() {
    _attempt = 0;
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
    debugPrint("Attempt: $_attempt");
    if (_attempt < 2) {
      _attempt++;
      throw Exception("Exception");
    }
    return Response(
      requestOptions: RequestOptions(path: url),
      data: {
        'total': 12,
        'items': List.generate(12, (i) => {'title': 'Item ${i + 1}'}),
      },
    );
  }
}

class HttpResourceRetryExample extends StatefulWidget {
  const HttpResourceRetryExample({super.key});

  @override
  State<HttpResourceRetryExample> createState() =>
      _HttpResourceRetryExampleState();
}

class _HttpResourceRetryExampleState extends State<HttpResourceRetryExample> {
  late final HttpResource<Map<String, dynamic>> resource;

  @override
  void initState() {
    super.initState();
    cesiumHttpServiceProvider.override(() => FakeRetryHttpService());
    resource = HttpResource(
      () => 'https://example.com/items',
      (data) => data as Map<String, dynamic>,
      maxRetryAttempts: 3,
    );
  }

  @override
  void dispose() {
    resource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: resource.pipe(
              loading: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator()],
                ),
              ),
              error: (context, err) => Center(child: Text('Error: $err')),
              value: (context, value) {
                final items = ((value['items']) as List<Map<String, dynamic>>)
                    .map((e) => e['title'] as String)
                    .toList();
                return Column(children: items.map((e) => Text(e)).toList());
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              cesiumHttpServiceProvider.reset();
              resource.reload();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
