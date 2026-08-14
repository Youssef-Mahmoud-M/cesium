## 1.0.0

Initial release with the following features:

- `ComputedResource`: a `ValueNotifier` that automatically reruns its computation when one of its dependencies changes.
- `FutureResource`: a `ValueNotifier` that exposes the current state of a `Future`, making it easier to integrate asynchronous results into UI.
- `HttpResource`: a `ValueNotifier` representing the state of a GET HTTP request for simpler UI integration.
- `PaginatedHttpResource`: similar to `HttpResource`, but with built-in support for infinite-scroll pagination.
- `CesiumService`: a base class for services that can be registered with the package's dependency helpers.
- Extensions for `Listenable` and `ValueNotifier` to simplify UI code.
- `ManagedListenerMixin`: a mixin for `StatefulWidget` that automatically removes added listeners during `dispose()`.
- Error logging: a centralized `Cesium` error API. Report errors with `Cesium.logError(error)` and register a handler with `Cesium.setErrorHandler(...)`.
