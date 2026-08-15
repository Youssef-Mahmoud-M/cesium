import 'package:flutter/foundation.dart';

/// Base class for long-lived services managed by Cesium.
///
/// Services should extend `CesiumService` and implement `reset()` to
/// clear internal state when the service is recycled by the framework or
/// test harness.
abstract class CesiumService extends ChangeNotifier {
  /// Reset the service to its initial state.
  void reset();
}
