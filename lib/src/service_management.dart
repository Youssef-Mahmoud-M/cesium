import 'package:cesium/cesium.dart';

final Map<Type, CesiumService> _services = {};
final Map<Type, CesiumService Function()> _factories = {};

/// Register a factory for a service type `T`.
///
/// The factory will be used to create the service instance when first
/// injected via `injectService<T>()` or when a `ServiceProvider` is used.
void register<T extends CesiumService>(T Function() factory) {
  _factories[T] = factory;
}

/// Register an overriding factory for service type `T`.
///
/// If a service instance of type `T` already exists it will be replaced
/// with a new instance produced by the override factory.
void registerOverride<T extends CesiumService>(T Function() factory) {
  _factories[T] = factory;
  if (_services.containsKey(T)) {
    _services[T] = _factories[T]!();
  }
}

/// Return the singleton instance of the registered service `T`.
///
/// If no instance exists it will be created using the registered factory.
/// Throws if no factory has been registered for `T`.
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

/// Reset (or recreate) the registered service instance for type `T`.
///
/// If an instance exists, its `reset()` method is called. If no instance
/// exists but a factory is registered, a new instance will be created.
void resetService<T extends CesiumService>() {
  if (_services.containsKey(T)) {
    final instance = _services[T]!;
    instance.reset();
  } else if (_factories.containsKey(T)) {
    _services[T] = _factories[T]!();
  }
}

/// Reset all currently created service instances by calling `reset()` on
/// each one.
void resetServices() {
  for (var instance in _services.values) {
    instance.reset();
  }
}

/// Helper to register and optionally override a service factory in a
/// concise, test-friendly way.
///
/// Example:
///
/// ```dart
/// final provider = ServiceProvider(() => MyService());
/// final service = provider.inject();
/// ```
class ServiceProvider<T extends CesiumService> {
  bool _registeredOverride = false;

  /// Whether an override factory has been registered for this provider.
  bool get registeredOverride => _registeredOverride;

  /// Create a `ServiceProvider` and register the primary factory.
  ServiceProvider(T Function() factory) {
    register<T>(factory);
  }

  /// Construct a service provider and register an override factory
  /// immediately. Useful in tests.
  ServiceProvider.withOverride(
    T Function() factory,
    T Function() overrideFactory,
  ) {
    register<T>(factory);
    registerOverride(overrideFactory);
    _registeredOverride = true;
  }

  /// Register an override factory for this provider.
  void override(T Function() overrideFactory) {
    if (_registeredOverride) return;
    registerOverride<T>(overrideFactory);
    _registeredOverride = true;
  }

  /// Retrieve the injected service instance.
  T inject() {
    return injectService<T>();
  }

  /// Reset the underlying service instance.
  void reset() {
    resetService<T>();
  }
}
