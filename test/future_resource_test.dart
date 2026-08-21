import 'package:cesium/src/future_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Future resource updates with correct value in success', () async {
    FutureResource<String> resource = FutureResource<String>(
      future: () async {
        await Future.delayed(Duration(milliseconds: 100));
        return "Hello";
      },
    );

    expect(resource.isLoading, true);

    await Future.delayed(Duration(milliseconds: 150));

    expect(resource.isLoading, false);
    expect(resource.result, "Hello");

    resource.dispose();
  });

  test('Future resource updates with error in failiure', () async {
    FutureResource<String> resource = FutureResource(
      future: () async {
        await Future.delayed(Duration(milliseconds: 100));
        throw Exception("Test exception");
      },
    );

    expect(resource.isLoading, true);

    await Future.delayed(Duration(milliseconds: 150));

    expect(resource.isLoading, false);
    expect(resource.error, isNotNull);

    resource.dispose();
  });
}
