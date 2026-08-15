// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class ExtensionsExample extends StatefulWidget {
  const ExtensionsExample({super.key});

  @override
  State<ExtensionsExample> createState() => _ExtensionsExampleState();
}

class _ExtensionsExampleState extends State<ExtensionsExample> {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  @override
  void dispose() {
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
            // Using `pipe` extension to render a ValueNotifier
            counter.pipe(
              (context, value) => Text(
                'Counter: $value',
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
