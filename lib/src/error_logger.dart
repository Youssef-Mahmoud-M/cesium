class Cesium {
  static void Function(Object)? _errorHandler;

  static void setErrorHandler(void Function(Object) errorHandler) {
    _errorHandler = errorHandler;
  }

  static void logError(Object error) {
    if (_errorHandler != null) {
      _errorHandler!(error);
    }
  }

  Cesium._internal();
}
