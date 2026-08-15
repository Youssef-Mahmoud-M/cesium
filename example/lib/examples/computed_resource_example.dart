// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class ComputedResourceExample extends StatefulWidget {
  const ComputedResourceExample({super.key});

  @override
  State<ComputedResourceExample> createState() =>
      _ComputedResourceExampleState();
}

class _ComputedResourceExampleState extends State<ComputedResourceExample> {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);
  late final ComputedResource<String> computed;

  @override
  void initState() {
    super.initState();
    computed = ComputedResource(() => 'Value is ${counter.value}', [counter]);
  }

  @override
  void dispose() {
    computed.dispose();
    counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            computed.pipe(
              (context, value) => Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => counter.value++,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
