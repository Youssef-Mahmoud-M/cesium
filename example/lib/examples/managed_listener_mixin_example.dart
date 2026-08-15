// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

// A mock global service that tracks user preferences or status
class AppSettingsService extends CesiumService {
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    notifyListeners();
  }

  @override
  void reset() {
    isDarkMode.value = true;
  }
}

final appSettingsServiceProvider = ServiceProvider(() => AppSettingsService());

class ManagedListenerExample extends StatefulWidget {
  const ManagedListenerExample({super.key});

  @override
  State<ManagedListenerExample> createState() => _ManagedListenerExampleState();
}

// Using ManagedListenerMixin to safely manage external service listeners
class _ManagedListenerExampleState extends State<ManagedListenerExample>
    with ManagedListenerMixin {
  final AppSettingsService _settingsService = appSettingsServiceProvider
      .inject();
  String _statusLog = 'Listening to service changes...';

  @override
  void initState() {
    super.initState();

    // Automatically tracked and cleaned up on dispose()! No manual removeListener needed.
    addListener(_settingsService, () {
      setState(() {
        _statusLog =
            'Theme changed to: ${_settingsService.isDarkMode.value ? "Dark" : "Light"}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _statusLog,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _settingsService.toggleTheme(),
              child: const Text('Toggle Service Theme'),
            ),
          ],
        ),
      ),
    );
  }
}
