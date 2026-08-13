import 'package:cesium/cesium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Error logger calls errorHandler on error with correct error', () {
    Cesium.setErrorHandler((error) {
      throw error == "Error";
    });

    bool caught = false;

    try {
      Cesium.logError("Error");
    } catch (e) {
      caught = e as bool;
    }

    expect(caught, true);
  });
}
