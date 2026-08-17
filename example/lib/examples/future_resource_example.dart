// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class FutureResourceExample extends StatefulWidget {
  const FutureResourceExample({super.key});

  @override
  State<FutureResourceExample> createState() => _FutureResourceExampleState();
}

class _FutureResourceExampleState extends State<FutureResourceExample> {
  late final FutureResource<String> resource = FutureResource(futureFunction);
  late final FutureResource<String> resourcePerserved = FutureResource(
    futureFunction,
    true,
  );
  late final FutureResource<String> resourceReattempt = FutureResource(
    () async {
      throw Exception("Test");
    },
    false,
    (_, reattempt) => reattemptFutureFunction(reattempt),
  );
  late final FutureResource<String> perservedResourceReattempt = FutureResource(
    () async {
      throw Exception("Test");
    },
    true,
    (_, reattempt) => reattemptFutureFunction(reattempt),
  );

  Future<String> reattemptFutureFunction(int attempt) async {
    debugPrint("Reattempt $attempt");
    await Future.delayed(const Duration(seconds: 2));
    if (attempt < 3) {
      throw Exception("Exception");
    }
    return "Loaded at  ${DateTime.now()}";
  }

  Future<String> futureFunction() async {
    await Future.delayed(const Duration(seconds: 2));
    return 'Loaded at ${DateTime.now()}';
  }

  @override
  void dispose() {
    resource.dispose();
    resourcePerserved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Normal Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resource.pipe(
              loading: (context) =>
                  const Center(child: CircularProgressIndicator()),
              error: (context, err) => Text('Error: $err'),
              value: (context, val) => Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resource.runNewFuture(futureFunction),
                    child: const Text('Run New'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resource.cancel(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Preserved Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resourcePerserved.pipe(
              loading: (context) =>
                  const Center(child: CircularProgressIndicator()),
              error: (context, err) => Text('Error: $err'),
              value: (context, val) => Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        resourcePerserved.runNewFuture(futureFunction),
                    child: const Text('Run New'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resourcePerserved.cancel(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Reattempt Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resourceReattempt.pipe(
              loading: (context) =>
                  const Center(child: CircularProgressIndicator()),
              error: (context, err) => Text('Error: $err'),
              value: (context, val) => Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resourceReattempt.runNewFuture(() async {
                      throw Exception("Test");
                    }),
                    child: const Text('Run New'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resourceReattempt.cancel(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Preserved Reattempt Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            perservedResourceReattempt.pipe(
              loading: (context) =>
                  const Center(child: CircularProgressIndicator()),
              error: (context, err) => Text('Error: $err'),
              value: (context, val) => Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        perservedResourceReattempt.runNewFuture(() async {
                          throw Exception("Test");
                        }),
                    child: const Text('Run New'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => perservedResourceReattempt.cancel(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
