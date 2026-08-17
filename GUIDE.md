# Guide for Cesium and best practices

## Http Resources

### Construction and use

There are two Http resources in Cesium `HttpResource<T>` and `PaginatedHttpResource<T>`. They both share a common set of parameters:

- `Iterable<Listenable> dependencies`: When one of the dependencies notifies the http resource, it auto reruns `urlBuilder` and `queryParametersBuilder` and then reruns the http request
- `Duration? debounceDuration`: To debounce reloading when dependencies update so that for example you can pass a `TextEditingController` and a debounce duration of 1 second, the http resource will wait until there have been no updates for 1 second then reload
- `Map<String, dynamic> headers` to customize the headers sent by the http resource in the request
- `T Function(dynamic data) transform` takes the response of the URL and transforms it into `T`
- `int maxRetryAttempts` the maximum amount of times the resource will retry on failure, defaults to 0

Each http resource has its own version of `queryParametersBuilder` and `urlBuilder`

For `HttpResource<T>` their signatures are `String Function() urlBuilder` and `Map<String, dynamic> Function()? queryParametersBuilder`

While for `PaginatedHttpResource<T>` their signatures are `String Function(int) urlBuilder` and `Map<String, dynamic> Function(int)? queryParametersBuilder`, it also has two of its own unique parameters which are:

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
PaginatedHttpResource<List<User>> usersResource = PaginatedHttpResource<UsersResponse>(
  urlBuilder: (page) => 'https://api.example.com/users',
  queryParametersBuilder: (page) => {'page': page.toString()},
  transform: (data) => UsersResponse.fromJson(data),
  getMaxPages: (response) => response.totalPages,
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

A `FutureResource<T>` is used to handle futures in the UI more cleanly it has the following parameters:

1. The future it will run which is of type `Future<T> Function()?`, if null it will stay loading until a future is passed to it through the `runNewFuture` function

2. To preserve the result or not which is a boolean, it defaults to false, if false then when loading a new future or when an error occurs the `result` property returns to null, if true when loading a new future the `result` property does not turn to null, it waits until the new future finishes and then replaces the `result` when an error occurs, the `result` property contains the last successful result and the `error` property contains the error

3. A function that is run when an error occurs to reattempt, it is optional but will help in retrying. It has a signature of `Future<T>? Function(Object error, int attempt)?`, if the return value is null it will stop reattempting.

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
FutureResource<List<User>>(
  (context) async => userService.fetchUsers(),
).pipe(
  loading: (context) => LoadingWidget(),
  error: (context, error) => ErrorWidget(message: error.toString()),
  value: (context, users) => UsersList(users: users),
);
```

## Computed resource

`ComputedResource<T>` is a `ValueNotifier<T>` that auto updates its value based on dependencies passed as the second parameter which is an `Iterable<Listenable>`, its parameters are:

1. The computation itself which is a `T Function()` that computes the value

2. The dependencies which are a `Iterable<Listenable>` when one of them notifies the computed resource it reruns the computation

3. An optional debounce `Duration` which makes it that it waits that long before rerunning the computation while listening to any changes from the dependencies

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
