/// Top-level helpers for global Cesium configuration and error forwarding.
class Cesium {
  static void Function(Object)? _errorHandler;

  /// Set a global error handler that will receive errors logged by the
  /// library (for example from background computations) or the user through `Cesium.logError`.
  static void setErrorHandler(void Function(Object) errorHandler) {
    _errorHandler = errorHandler;
  }

  /// Log an error through the configured handler if present.
  static void logError(Object error) {
    if (_errorHandler != null) {
      _errorHandler!(error);
    }
  }

  Cesium._internal();
}
