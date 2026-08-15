// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class ErrorLoggerExample extends StatefulWidget {
  const ErrorLoggerExample({super.key});

  @override
  State<ErrorLoggerExample> createState() => _ErrorLoggerExampleState();
}

class _ErrorLoggerExampleState extends State<ErrorLoggerExample> {
  final List<Object> errors = [];

  @override
  void initState() {
    super.initState();
    Cesium.setErrorHandler((err) {
      errors.add(err);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () =>
                Cesium.logError('Manual error at ${DateTime.now()}'),
            child: const Text('Log Error'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Captured Errors:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: errors.isEmpty
                ? const Center(child: Text('No errors captured yet.'))
                : ListView.separated(
                    itemBuilder: (context, index) =>
                        Text(errors[index].toString()),
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: errors.length,
                  ),
          ),
        ],
      ),
    );
  }
}
