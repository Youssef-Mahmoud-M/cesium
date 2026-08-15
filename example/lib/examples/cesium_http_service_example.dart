// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

// 1. Define a custom service that depends on CesiumHttpService
class DataSubmissionService extends CesiumService {
  final CesiumHttpService _httpService = cesiumHttpServiceProvider.inject();

  final ValueNotifier<bool> isSubmitting = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastResponse = ValueNotifier<String?>(null);

  Future<void> submitData(String title) async {
    isSubmitting.value = true;
    lastResponse.value = null;

    try {
      // Using httpbin mirror endpoint to echo back the POST request data
      final response = await _httpService.post(
        'https://httpbin.org/post',
        data: {'title': title},
      );

      final echoedData = response.data['json']?['title'] ?? 'Unknown';
      lastResponse.value =
          'Success! Echoed title: "$echoedData" (Status ${response.statusCode})';
    } catch (e) {
      lastResponse.value = 'Error: $e';
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void reset() {
    isSubmitting.value = false;
    lastResponse.value = null;
  }
}

// 2. Provide the service
final dataSubmissionServiceProvider = ServiceProvider(
  () => DataSubmissionService(),
);

// 3. UI Widget consuming the service
class CesiumHttpServiceExample extends StatefulWidget {
  const CesiumHttpServiceExample({super.key});

  @override
  State<CesiumHttpServiceExample> createState() =>
      _CesiumHttpServiceExampleState();
}

class _CesiumHttpServiceExampleState extends State<CesiumHttpServiceExample> {
  final DataSubmissionService _service = dataSubmissionServiceProvider.inject();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CesiumHttpService Mirror POST Example',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Data to Echo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _service.isSubmitting.pipe(
            (context, isSubmitting) => ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () => _service.submitData(_controller.text),
              child: Text(isSubmitting ? 'Sending...' : 'Send POST Request'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Response Result:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _service.lastResponse.pipe(
            (context, response) => Text(
              response ?? 'No submission yet.',
              style: TextStyle(
                color: response != null && response.startsWith('Error')
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
