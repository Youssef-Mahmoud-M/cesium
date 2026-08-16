// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';
import 'package:dio/dio.dart';

class FakePaginatedHttpService extends CesiumHttpService {
  int _pageCalled = 0;

  @override
  Future<Response> get(
    String url, {
    Object? data,
    Options? options,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    _pageCalled = int.parse(params?['page']?.toString() ?? '1');
    final start = (_pageCalled - 1) * 5 + 1;
    return Response(
      requestOptions: RequestOptions(path: url),
      data: {
        'total': 20,
        'items': List.generate(5, (i) => {'title': 'Item ${start + i}'}),
      },
    );
  }
}

class PaginatedHttpResourceExample extends StatefulWidget {
  const PaginatedHttpResourceExample({super.key});

  @override
  State<PaginatedHttpResourceExample> createState() =>
      _PaginatedHttpResourceExampleState();
}

class _PaginatedHttpResourceExampleState
    extends State<PaginatedHttpResourceExample> {
  late final PaginatedHttpResource<Map<String, dynamic>> resource;

  @override
  void initState() {
    super.initState();
    cesiumHttpServiceProvider.override(() => FakePaginatedHttpService());
    resource = PaginatedHttpResource(
      (_) => 'https://example.com/items',
      (data) => data as Map<String, dynamic>,
      (page) => {'page': page},
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
            child: resource.pipePaginated<Map<String, dynamic>>(
              loading: (context, progress) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('Loading: ${(progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              error: (context, err) => Center(child: Text('Error: $err')),

              // getItems maps the raw response page into a List of individual items (T2)
              getItems: (item) => (item['items'] as List)
                  .map((e) => e as Map<String, dynamic>)
                  .toList(),

              // itemBuilder receives one pre-extracted item (T2) and its global index
              itemBuilder: (context, itemValue, index) {
                final title = itemValue['title']?.toString() ?? 'Unknown';
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(title),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => resource.loadMore(),
            child: const Text('Load More Manually'),
          ),
        ],
      ),
    );
  }
}
