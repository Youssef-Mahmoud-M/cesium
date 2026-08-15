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

## 1.0.1

- Added a `NOTICE` file for dependency license attribution (`async`, `dio`, `Flutter`).

## 1.1.0

- Added a centralized `CesiumHttpService` with HTTP helpers and reset support for cleaner dependency injection and testing.
- Introduced a shared `HttpResourceBase` to consolidate request execution, debounce handling, dependency reloading, and progress tracking.
- Updated `HttpResource` and `PaginatedHttpResource` to use the new base flow while preserving pagination behavior and result accumulation.
- Expanded the service management API with override/reset patterns to support testing and configuration flexibility.
- Added focused coverage for initial loads, errors, dependency-triggered refreshes, and paginated requests.

## 1.1.1

- Added inlineEnd to paginated http response so that when the user reaches an end it can display something
- Added inlineStart to paginated http response so that widgets can be inserted at the start of the ListView.builder
