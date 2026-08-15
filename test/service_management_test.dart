import 'package:flutter_test/flutter_test.dart';

import 'package:cesium/cesium.dart';

class TestService extends CesiumService {
  int _value;
  int get value => _value;
  set value(int value) {
    _value = value;
    notifyListeners();
  }

  TestService(this._value);

  @override
  void reset() {
    value = 1;
  }
}

void main() {
  tearDown(() {
    resetServices();
  });

  setUpAll(() {
    register<TestService>(() => TestService(1));
  });

  test('Services are singletons', () {
    TestService service = injectService();
    service.value++;
    TestService service2 = injectService();
    expect(service.value, service2.value);
  });

  test('Reset service resets the target service', () {
    TestService service = injectService();
    service.value++;
    resetService<TestService>();
    expect(service.value, 1);
  });

  test('Reset services resets all services', () {
    TestService service = injectService();
    service.value++;
    resetServices();
    expect(service.value, 1);
  });
}
