import 'package:cesium/cesium.dart';

final Map<Type, CesiumService> _services = {};
final Map<Type, CesiumService Function()> _factories = {};

void register<T extends CesiumService>(T Function() factory) {
  _factories[T] = factory;
}

void registerOverride<T extends CesiumService>(T Function() factory) {
  _factories[T] = factory;
  if (_services.containsKey(T)) {
    _services[T] = _factories[T]!();
  }
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

class ServiceProvider<T extends CesiumService> {
  bool _registeredOverride = false;
  bool get registeredOverride => _registeredOverride;
  ServiceProvider(T Function() factory) {
    register<T>(factory);
  }

  ServiceProvider.withOverride(
    T Function() factory,
    T Function() overrideFactory,
  ) {
    register<T>(factory);
    registerOverride(overrideFactory);
    _registeredOverride = true;
  }

  void override(T Function() overrideFactory) {
    if (_registeredOverride) return;
    registerOverride<T>(overrideFactory);
    _registeredOverride = true;
  }

  T inject() {
    return injectService<T>();
  }

  void reset() {
    resetService<T>();
  }
}
