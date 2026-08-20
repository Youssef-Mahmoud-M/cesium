// ignore_for_file: public_member_api_docs

import 'package:cesium_example/examples/action_resource_example.dart';
import 'package:cesium_example/examples/http_resource_retry_example.dart';
import 'package:flutter/material.dart';
import 'examples/service_management_example.dart';
import 'examples/computed_resource_example.dart';
import 'examples/error_logger_example.dart';
import 'examples/extensions_example.dart';
import 'examples/future_resource_example.dart';
import 'examples/http_resource_example.dart';
import 'examples/paginated_http_resource_example.dart';
import 'examples/managed_listener_mixin_example.dart';
import 'examples/cesium_http_service_example.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cesium Examples', home: const ExampleList());
  }
}

class ExampleList extends StatelessWidget {
  const ExampleList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, Widget Function()>>[
      {'Service Management': () => const ServiceManagementExample()},
      {'ComputedResource': () => const ComputedResourceExample()},
      {'Error Logger': () => const ErrorLoggerExample()},
      {'Extensions (pipe)': () => const ExtensionsExample()},
      {'FutureResource': () => const FutureResourceExample()},
      {'Action Resource': () => const ActionResourceExample()},
      {'HttpResource': () => const HttpResourceExample()},
      {'Retry HttpResource': () => const HttpResourceRetryExample()},
      {'PaginatedHttpResource': () => const PaginatedHttpResourceExample()},
      {'ManagedListenerMixin': () => const ManagedListenerExample()},
      {'CesiumHttpService': () => const CesiumHttpServiceExample()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cesium Examples'),
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final title = items[index].keys.first;
          final builder = items[index][title]!;
          return ListTile(
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(title), scrolledUnderElevation: 0),
                  body: SafeArea(child: builder()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
