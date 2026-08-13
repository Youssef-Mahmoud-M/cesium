import 'package:cesium/cesium.dart';
import 'package:cesium/src/computed_resource.dart';
import 'package:flutter_test/flutter_test.dart';

import 'service_injection_test.dart';

void main() {
  test('Computed resource changes when dependencies change', () {
    register(() => TestService(1));
    TestService service = injectService();
    ComputedResource<String> valueString = ComputedResource(
      () => service.value.toString(),
      [service],
    );
    String oldValue = valueString.value;
    service.value++;
    expect(oldValue, "1");
    expect(valueString.value, "2");
    valueString.dispose();
  });
}
