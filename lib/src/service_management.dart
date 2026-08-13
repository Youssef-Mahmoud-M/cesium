import 'package:cesium/cesium.dart';

final Map<Type, CesiumService> _services = {};
final Map<Type, CesiumService Function()> _factories = {};

void register<T extends CesiumService>(T Function() factory) {
  _factories[T] = factory;
}

T injectService<T extends CesiumService>() {
  if (_services.containsKey(T)) {
    return _services[T]! as T;
  }

  final factory = _factories[T];
  if (factory == null) {
    throw Exception('Service of type $T is not registered!');
  }

  final instance = factory() as T;
  _services[T] = instance;
  return instance;
}

void resetService<T extends CesiumService>() {
  if (_services.containsKey(T)) {
    final instance = _services[T]!;
    instance.reset();
  } else if (_factories.containsKey(T)) {
    _services[T] = _factories[T]!();
  }
}

void resetServices() {
  for (var instance in _services.values) {
    instance.reset();
  }
}
