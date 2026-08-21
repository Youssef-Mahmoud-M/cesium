// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class HttpResourceExample extends StatefulWidget {
  const HttpResourceExample({super.key});

  @override
  State<HttpResourceExample> createState() => _HttpResourceExampleState();
}

class _HttpResourceExampleState extends State<HttpResourceExample>
    with ManagedListenerMixin {
  late final HttpResource<List<String>> coffeeResource = manage(
    HttpResource(
      () => 'https://api.sampleapis.com/coffee/hot',
      (data) => (data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['title'].toString())
          .toList(),
    ),
  );

  Future<void> _reload() async {
    final completer = Completer<void>();
    coffeeResource.addListener(() {
      if (!coffeeResource.isLoading) completer.complete();
    });
    coffeeResource.reload();
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'HttpResource Example',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: coffeeResource.pipeProgress(
              loading: (context, progress) =>
                  const Center(child: CircularProgressIndicator()),
              error: (context, error) => Center(child: Text('Error: $error')),
              value: (context, items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No items'));
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) =>
                        ListTile(title: Text(items[index])),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => coffeeResource.reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}
