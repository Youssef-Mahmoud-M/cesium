// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

class ActionResourceExample extends StatefulWidget {
  const ActionResourceExample({super.key});

  @override
  State<ActionResourceExample> createState() => _ActionResourceExampleState();
}

class _ActionResourceExampleState extends State<ActionResourceExample> {
  late final ActionResource<String> resource = ActionResource();
  late final ActionResource<String> resourcePerserved = ActionResource(true);
  late final ActionResource<String> resourceReattempt = ActionResource(
    false,
    (_, reattempt) => reattemptFutureFunction(reattempt),
  );
  late final ActionResource<String> perservedResourceReattempt = ActionResource(
    true,
    (_, reattempt) => reattemptFutureFunction(reattempt),
  );
  late final ActionResource<String> failiureResource = ActionResource();

  Future<String> reattemptFutureFunction(int attempt) async {
    debugPrint("Reattempt $attempt");
    await Future.delayed(const Duration(seconds: 2));
    if (attempt < 3) {
      throw Exception("Exception");
    }
    return "Loaded at ${DateTime.now()}";
  }

  Future<String> futureFunction() async {
    await Future.delayed(const Duration(seconds: 2));
    return 'Loaded at ${DateTime.now()}';
  }

  Future<String> failiureFunction() async {
    await Future.delayed(Duration(seconds: 2));
    throw Exception("Test");
  }

  @override
  void dispose() {
    resource.dispose();
    resourcePerserved.dispose();
    resourceReattempt.dispose();
    perservedResourceReattempt.dispose();
    failiureResource.dispose();
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
              "Normal Action ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resource.pipe(
              (context, val) => Text(
                "Current status is ${switch (val.status) {
                  ActionStatus.idle => "Idle",
                  ActionStatus.loading => "Loading",
                  ActionStatus.error => "Error ${val.error}",
                  ActionStatus.done => "Done",
                }} \nCurrent Value: ${val.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            resource.pipeButton(
              buttonBuilder: (context, status, child) => Row(
                children: [
                  Expanded(
                    child: disabled(
                      disabled: status == ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => resource.runNewAction(futureFunction),
                        child: const Text('Run New'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: disabled(
                      disabled: status != ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => resource.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Preserved Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resourcePerserved.pipe(
              (context, val) => Text(
                "Current status is ${switch (val.status) {
                  ActionStatus.idle => "Idle",
                  ActionStatus.loading => "Loading",
                  ActionStatus.error => "Error ${val.error}",
                  ActionStatus.done => "Done",
                }} \nCurrent Value: ${val.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            resourcePerserved.pipeButton(
              buttonBuilder: (context, status, child) => Row(
                children: [
                  Expanded(
                    child: disabled(
                      disabled: status == ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () =>
                            resourcePerserved.runNewAction(futureFunction),
                        child: const Text('Run New'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: disabled(
                      disabled: status != ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => resourcePerserved.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Reattempt Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resourceReattempt.pipe(
              (context, val) => Text(
                "Current status is ${switch (val.status) {
                  ActionStatus.idle => "Idle",
                  ActionStatus.loading => "Loading",
                  ActionStatus.error => "Error ${val.error}",
                  ActionStatus.done => "Done",
                }} \nCurrent Value: ${val.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            resourceReattempt.pipeButton(
              buttonBuilder: (context, status, _) => Row(
                children: [
                  Expanded(
                    child: disabled(
                      disabled: status == ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () =>
                            resourceReattempt.runNewAction(() async {
                              throw Exception("Test");
                            }),
                        child: const Text('Run New'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: disabled(
                      disabled: status != ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => resourceReattempt.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Preserved Reattempt Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            perservedResourceReattempt.pipe(
              (context, val) => Text(
                "Current status is ${switch (val.status) {
                  ActionStatus.idle => "Idle",
                  ActionStatus.loading => "Loading",
                  ActionStatus.error => "Error ${val.error}",
                  ActionStatus.done => "Done",
                }} \nCurrent Value: ${val.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            perservedResourceReattempt.pipeButton(
              buttonBuilder: (context, status, _) => Row(
                children: [
                  Expanded(
                    child: disabled(
                      disabled: status == ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () =>
                            perservedResourceReattempt.runNewAction(() async {
                              throw Exception("Test");
                            }),
                        child: const Text('Run New'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: disabled(
                      disabled: status != ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => perservedResourceReattempt.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Error Resource",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            failiureResource.pipe(
              (context, val) => Text(
                "Current status is ${switch (val.status) {
                  ActionStatus.idle => "Idle",
                  ActionStatus.loading => "Loading",
                  ActionStatus.error => "Error, ${val.error}",
                  ActionStatus.done => "Done",
                }} \nCurrent Value: ${val.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            failiureResource.pipeButton(
              buttonBuilder: (context, status, _) => Row(
                children: [
                  Expanded(
                    child: disabled(
                      disabled: status == ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () =>
                            failiureResource.runNewAction(failiureFunction),
                        child: const Text('Run New'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: disabled(
                      disabled: status != ActionStatus.loading,
                      child: ElevatedButton(
                        onPressed: () => failiureResource.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget disabled({bool disabled = false, required Widget child}) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: IgnorePointer(ignoring: disabled, child: child),
    );
  }
}
