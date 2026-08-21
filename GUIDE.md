# Guide for Cesium and best practices

## Http Resources

### Construction and use

There are two Http resources in Cesium `HttpResource<T>` and `PaginatedHttpResource<T>`. 

Constructors:

```dart
HttpResource<T>(
  String Function() urlBuilder,
  T Function(dynamic data) transform, {
    Map<String, dynamic> Function()? queryParametersBuilder,
    Iterable<Listenable> dependecies = const [],
    Duration? debounceDuration,
    Map<String, dynamic> headers = const {},
    int maxRetryAttempts = 0,
  }
);

PaginatedHttpResource<T>(
  String Function(int page) urlBuilder,
  T Function(dynamic data) transform,
  Map<String, dynamic> Function(int page) queryParamatersBuilder, {
    int Function(T)? getMaxPages,
    Iterable<Listenable> dependecies = const [],
    Duration? debounceDuration,
    Map<String, dynamic> headers = const {},
    int maxRetryAttempts = 0,
    int startPage = 1,
  }
);
```

Common optional parameters:

- `Iterable<Listenable> dependecies`: When one of the dependencies notifies the http resource, it auto reruns `urlBuilder` and the query builder and then reruns the http request.
- `Duration? debounceDuration`: Debounces reloads when dependencies update, so a `TextEditingController` can trigger a reload only after the configured idle period.
- `Map<String, dynamic> headers`: Custom request headers.
- `int maxRetryAttempts`: Maximum retry count on failure.

`PaginatedHttpResource<T>` also exposes:

- `int Function(T)? getMaxPages` takes the response data and returns the total number of pages available. This is recommended so that the resource automatically stops pagination at the correct page and prevents unnecessary requests

- `int startPage` determines which page to start from and to reset to when reload is called on the resource or when one of the dependencies change

### Piping into UI

For `HttpResource<T>`, it is recommended to use `pipe` whenever the loading state does not need progress as it is better in terms of performance. it has the following parameters:

- `Widget Function(BuildContext context) loading`

- `Widget Function(BuildContext, Object) error`

- `Widget Function(BuildContext, T value) value`

It also exposes another method for when you need progress `pipeProgress`. It has the following parameters:

- `Widget Function(BuildContext context, double progress) loading`

- `Widget Function(BuildContext, Object) error`

- `Widget Function(BuildContext, T value) value`

For `PaginatedHttpResource<T>` it exposes `pipePaginated` which has the following parameters:

- `Widget Function(BuildContext context, double progress) loading` - widget shown while fetching the first page

- `Widget Function(BuildContext, Object) error` - widget shown when an error occurs

- `Widget Function(BuildContext, T2 value, int index) itemBuilder` - builder for each item in the list

- `required List<T2> Function(T item) getItems` - extracts the list of items from the paginated response

- `List<Widget> Function(BuildContext)? inlineStart` - optional widgets to display at the start of the list before any items

- `Widget Function(BuildContext, double progress)? inlineLoading` - optional widget shown while loading additional pages (for infinite scroll)

- `Widget Function(BuildContext, Object)? inlineError` - optional widget shown when an error occurs while loading additional pages

- `Widget Function(BuildContext)? inlineEnd` - optional widget to display at the end of the list after all items

- All `ListView.builder` parameters

**Example:**

```dart
final usersResource = PaginatedHttpResource<User>(
  (page) => 'https://api.example.com/users',
  (data) => User.fromJson(data),
  (page) => {'page': page.toString()},
  getMaxPages: (user) => user.totalPages,
  startPage: 1,
);

usersResource.pipePaginated(
  loading: (context, progress) => CircularProgressIndicator(value: progress),
  error: (context, error) => Text('Error: $error'),
  itemBuilder: (context, user, index) => ListTile(title: Text(user.name)),
  getItems: (response) => response.users,
  inlineLoading: (context, progress) => Padding(
    padding: EdgeInsets.all(16),
    child: CircularProgressIndicator(value: progress),
  ),
);
```

Both of these methods return a `Widget`

## Future resource

A `FutureResource<T>` is used to handle futures in the UI more cleanly.

Constructor signature:

```dart
FutureResource<T>({
  Future<T> Function()? future,
  bool perserveResult = false,
  Future<T>? Function(Object error, int attempt)? retryActionOnError,
});
```

The required work is still passed through the `future` callback when you want the resource to start immediately. The other arguments are optional behavior settings and are named parameters.

- `future`: the initial async work to run, or `null` to keep the resource idle until `runNewFuture()` is called.
- `perserveResult`: when `true`, the last successful value remains visible while a retry or reload is in progress.
- `retryOnError`: optional retry callback. Return `null` to stop retrying.

There are 4 properties on a `FutureResource<T>`:

- `FutureResourceValue<T> value`: It contains the current state

- `bool isLoading`: A shorthand for `value.isLoading`

- `Object? error`: A shorthand for `value.error`

- `T? result`: A shorthand for `value.value`

There are 3 methods on a `FutureResource<T>`:

- `void runNewFuture(Future<T> Function() newFuture, [T? optimisticValue])`: A method to run a new future on the current resource, if one is already running it will be cancelled and replaced by the new future. If `optimisticValue` is passed, it will be the value in `result` until the operation is completed

- `cancel()`: Cancels the current running future if there is one

- `pipe`: It is used to pipe the current resource into the widget tree with the following parameters:
  
  - `Widget Function(BuildContext context) loading`
  - `Widget Function(BuildContext, Object) error`
  - `Widget Function(BuildContext, T value) value`
    It returns a Widget and auto rebuilds when the state changes

## Action resource

An `ActionResource<T>` is used to handle actions that are not initiated right as the page starts, for example a login. It has 4 states:

- idle
- loading
- error
- done

Constructor signature:

```dart
ActionResource<T>({
  bool perserveResult = false,
  Future<T>? Function(Object error, int attempt)? retryOnError,
  Future<T> Function()? future,
  VoidCallback? onSuccess,
  VoidCallback? onFailure,
});
```

The action callback is still passed through the named `future` argument when you want the action to begin immediately. The other settings are optional named parameters.

- `perserveResult`: keeps the last successful result while a new attempt is loading.
- `retryOnError`: optional retry callback for transient failures.
- `future`: optional initial action to execute immediately.
- `onSuccess` and `onFailure`: fire after a successful or failed action.

There is a definition for an enum called `ActionStatus`, it has 4 possible states:

- loading

- idle

- error

- done

There are 4 properties on a n`ActionResource<T>`:

- `ActionResourceValue<T> value`: It contains the current state

- `ActionStatus status`: A shorthand for `value.status`

- `Object? error`: A shorthand for `value.error`

- `T? result`: A shorthand for `value.value`

There are 3 methods on an `ActionResource<T>`:

- `void runNewAction(Future<T> Function() newFuture, [T? optimisticValue])`: A method to run a new future on the current resource, if one is already running it will be cancelled and replaced by the new future. If `optimisticValue` is passed, it will be the value in `result` until the operation is completed

- `cancel()`: Cancels the current running action if there is one

- `pipeButton`: It is used to pipe the current resource into the widget tree with the following parameters:
  
  - `Widget Function(BuildContext, ActionStatus, Widget?) buttonBuilder`
  - `Widget? child`
    It returns a Widget and auto rebuilds when the state changes, the child does not rebuild.

## Services

### Registration and injection

Services are classes that extend `CesiumService` so that they can be handled by the dependency injection system. Dependency injection has two ways:

1. Manual registration using `register<T>(T Function() factory)` and can be injected using the `injectService()` function:
   
   ```dart
   //test_service.dart
   class TestService extends CesiumService {
       @override
       void reset() {}
   }
   
   //main.dart
   void main() {
       register<TestService>(() => TestService());
   }
   
   // Later on injected using
   final service = injectService<TestService>();
   ```

2. Creating a `ServiceProvider<T>` that automatically registers the service and is used for inject via its method `inject()`:
   
   ```dart
   //test_service.dart
   final testServiceProvider = ServiceProvider(() => TestService());
   
   class TestService extends CesiumService {
       @override
       void reset() {}
   }
   
   //Later on injected using
   final service = testServiceProvider.inject();
   ```

The second approach is more recommended as it makes it easier to use services in tests.

### Testing

Services often need to be overridden with mock versions to test UI or other services, override services must be a child of the original service. Any injection of the original service is replaced with the override. There are two ways to override services:

- The `registerOverride<T>(T Function())` where `T` is the service you want to override, this is used when manual registration is used:
  
  ```dart
  class MockTestService extends TestService {
      //Any custom overrides will be put here
  }
  
  void main() {
      registerOverride<TestService>(() => MockTestService());
  
      //Your unit tests
  }
  ```

- The `override(T Function())` on the ServiceProvider of the service:
  
  ```dart
  class MockTestService extends TestService {
      //Any custom overrides will be put here
  }
  
  void main() {
      testServiceProvider.override(() => MockTestService());
  
      //Your unit tests
  }
  ```

### Writing services

Preferably services should have methods with the signature `Future<DataType> getAction({String parameter})` for resource fetching so that it can be piped into a `FutureResource<T>` for more concise code but if a service does need to cache its data for example for sharing to multiple locations it should do so in a `ValueNotifier<FutureResourceValue<DataType>>` because it has an extension `pipe` for more concise UI code. Services need to implement the `reset` function that returns the service to its original state and optionally notifies the listeners of the service. All values that directly interact with the UI should be `ValueNotifier<T>` so that UI can update cleanly and efficiently.

**Example service:**

```dart
// Simple service with Future methods (preferred approach)
class UserService extends CesiumService {
  Future<User> fetchUser(String userId) async {
    final response = await http.get(Uri.parse('https://api.example.com/users/$userId'));
    return User.fromJson(jsonDecode(response.body));
  }

  @override
  void reset() {
    // No cached state to reset
  }
}

// Service with cached data shared across multiple UI locations
class UserService extends CesiumService {
  final _currentUserNotifier = ValueNotifier<FutureResourceValue<User>>(
    FutureResourceValue(), // Default constructor is the loading state
  );

  ValueNotifier<FutureResourceValue<User>> get currentUserNotifier => _currentUserNotifier;

  Future<void> loadUser(String userId) async {
    _currentUserNotifier.value = FutureResourceValue();
    try {
      final response = await http.get(Uri.parse('https://api.example.com/users/$userId'));
      final user = User.fromJson(jsonDecode(response.body));
      _currentUserNotifier.value = FutureResourceValue.value(user);
    } catch (e) {
      _currentUserNotifier.value = FutureResourceValue.error(e);
    }
  }

  @override
  void reset() {
    _currentUserNotifier.value = FutureResourceValue();
  }
}
```

### Error handling

Both `HttpResource` and services should handle errors gracefully:

- **HttpResource errors** are passed to the `error` callback in `pipe`/`pipeProgress`/`pipePaginated`. The error object contains the exception that was thrown during the request.

- **Service errors** are automatically caught by `FutureResource` and passed to the `error` callback. For services with cached data, catch errors in the service method and update the `ValueNotifier` with `FutureResourceValue.error()`

**Error handling example:**

```dart
FutureResource<List<User>> futureResource = FutureResource<List<User>>(
  (context) async => userService.fetchUsers(),
);

futureResource.pipe(
  loading: (context) => LoadingWidget(),
  error: (context, error) => ErrorWidget(message: error.toString()),
  value: (context, users) => UsersList(users: users),
);
```

### Extras

Services can contain any type of resource if it needs to be shared across different pages, such resources must not be disposed in the UI as it can lead to unexpected results.

## Computed resource

`ComputedResource<T>` is a `ValueNotifier<T>` that auto updates its value based on dependencies passed as the second parameter which is an `Iterable<Listenable>`.
Constructor signature:

```dart
ComputedResource(
    T Function() computation,
    Iterable<Listenable> dependencies, {
    Duration? debounceDuration,
  })
```

1. `T Function() computation` the function that computes the value

2. `Iterable<Listenable> dependencies` when one of them notifies the computed resource it reruns the computation

3. `Duration? debounceDuration` which makes it that it waits the duration before rerunning the computation while listening to any changes from the dependencies

## Managed listener mixin

The `ManagedListenerMixin` is a mixin on `State` classes that helps in lifecycle management of listeners `ChangeNotifier` objects it exposes 3 functions

- `addListener(Listenable listenable, void Function() listener)` which adds the listener to the listenable and auto removes it on dispose without manual code in the dispose block

- `bool removeListener(Listenable listenable, void Function() listener)` removes the listener from a listenable if it was on the listener it returns true if not it returns false

- `N manage<N extends ChangeNotifier>(N listenable)` auto disposes change notifiers when the state disposes

```dart
class _MyWidgetState extends State<MyWidget> with ManagedListenerMixin {
    late final textEditingController = manage(TextEditingController()); // auto disposes the controller

    @override
    void initState() {
        addListener(textEditingController, () {
            setState(() {});
        });
    }

    // Build the widget
}
```

#### Extensions on Types

Cesium provides convenient extensions on existing Flutter types like `ValueNotifier<T>`, `Listenable`, and `List<Listenable>` to help you render widgets into the tree with minimal boilerplate.

### 1. `ValueNotifier<T>` Extensions

- `pipe`: Takes a `Widget Function(BuildContext context, T value)` builder and wraps the notifier in a `ValueListenableBuilder<T>`.

- `pipeChild`: Like `pipe`, but takes an optional static `Widget? child` parameter. The child widget is passed to the builder and is **not** rebuilt when the `ValueNotifier` updates, which is great for performance optimization.

Cesium provides many extensions on existing flutter types. For `ValueNotifier<T>` there are two extensions:

- `pipe` which takes a `Widget Function(BuildContext, T)` as its builder. It just makes a `ValueListenableBuilder<T>` and passes the builder to it.

- `pipeChild` which takes a `Widget Function(BuildContext, T, Widget?)` as its builder and an optional parameter `Widget? child` which passes this child to the builder and the child is not rebuilt when the `ValueNotifier` updates

**Example:**

```dart
final countNotifier = ValueNotifier<int>(0);

// Simple pipe
final widget = countNotifier.pipe(
  (context, count) => Text('Count: $count'),
);

// Pipe with a static optimization child
final optimizedWidget = countNotifier.pipeChild(
  (context, count, staticChild) => Column(
    children: [
      Text('Count: $count'),
      staticChild!, // This child never rebuilds on state change
    ],
  ),
  child: const ExpensiveStaticWidget(),
);
```

### 2. `ValueNotifier<FutureResourceValue<T>>` Extensions

For cached resources or services managing state via a `ValueNotifier`, Cesium provides a specialized `pipe` extension to handle loading, error, and value states out of the box:

```dart
service.currentUserNotifier.pipe(
  loading: (context) => const CircularProgressIndicator(),
  error: (context, error) => Text('Error: $error'),
  value: (context, user) => Text('Welcome, ${user.name}'),
);
```

3. `Listenable` and `List<Listenable>` Extensions

You can also pipe generic `Listenable` objects (like a `ChangeNotifier`) or a list of multiple listenables merged via `Listenable.merge`:

```dart
// Single listenable
myChangeNotifier.pipe((context) => Text('Notified!'));

// Multiple listenables merged automatically
[controllerA, controllerB].pipe((context) => MyCustomWidget());
```

Both generic `Listenable` extensions also provide a `pipeChild` variant for forwarding a static unbuilding child widget.
