import 'package:cesium/cesium.dart';
import 'package:flutter/material.dart';

class StreamManagementExample extends StatefulWidget {
  const StreamManagementExample({super.key});

  @override
  State<StreamManagementExample> createState() =>
      _StreamManagementExampleState();
}

class _StreamManagementExampleState extends State<StreamManagementExample> {
  final stream = _makeStream(8).asBroadcastStream();
  final errorStream = _makeStreamWithErrors(8).asBroadcastStream();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Column(
                children: [
                  const Text(
                    "Without errors: ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Pipe single: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  stream.pipeSingle((context, snapshot) {
                    final state = snapshot.connectionState;
                    if (state == ConnectionState.none ||
                        state == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    return Text("Current value: ${snapshot.data}");
                  }),
                  const Text(
                    "Pipe separated: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  stream.pipeSeparated(
                    noneBuilder: (_, _) => const SizedBox.shrink(),
                    waitingBuilder: (_, _) => const SizedBox.shrink(),
                    activeBuilder: (_, value) =>
                        Text("Current value: ${value}"),
                    doneBuilder: (_, value) => Text("Current value: ${value}"),
                  ),
                  const Text(
                    "Pipe aggregated: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  stream.pipeAggregated(
                    (_, values, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: values.map((e) {
                        if (e.data != null)
                          return Text("Value: ${e.data}");
                        else
                          return Text("Error: ${e.error}");
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  const Text(
                    "With errors: ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Pipe single: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  errorStream.pipeSingle((context, snapshot) {
                    final state = snapshot.connectionState;
                    if (state == ConnectionState.none ||
                        state == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    return Text("Current value: ${snapshot.data}");
                  }),
                  const Text(
                    "Pipe separated: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  errorStream.pipeSeparated(
                    errorBuilder: (_, error) => Text("Error: $error"),
                    noneBuilder: (_, _) => const SizedBox.shrink(),
                    waitingBuilder: (_, _) => const SizedBox.shrink(),
                    activeBuilder: (_, value) =>
                        Text("Current value: ${value}"),
                    doneBuilder: (_, value) => Text("Current value: ${value}"),
                  ),
                  const Text(
                    "Pipe aggregated: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  errorStream.pipeAggregated(
                    (_, values, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: values.map((e) {
                        if (e.data != null)
                          return Text("Value: ${e.data}");
                        else
                          return Text("Error: ${e.error}");
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Stream<int> _makeStream(int count) async* {
  for (var i = 0; i < count; i++) {
    yield i;
    await Future.delayed(Duration(milliseconds: 500));
  }
}

Stream<int> _makeStreamWithErrors(int count) async* {
  for (var i = 0; i < count; i++) {
    if (i == (count / 2).toInt()) {
      yield* Stream.error("This is an error");
      await Future.delayed(Duration(milliseconds: 1000));
    }
    yield i;
    await Future.delayed(Duration(milliseconds: 500));
  }
}
