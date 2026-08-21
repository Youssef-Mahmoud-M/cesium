# Cesium

A lightweight Flutter state management library built around `Listenable`, `ChangeNotifier`, and `ValueNotifier` to complement the Flutter ecosystem without replacing it.

Cesium gives you small, composable building blocks for async loading states, derived values, HTTP-backed resources, and service registration so you can keep your app logic simple and reactive.

## Documentation

Check out the official [Cesium Guide & Best Practices](https://github.com/Youssef-Mahmoud-M/cesium/blob/main/GUIDE.md).

## Features

- `FutureResource<T>` for loading, success, and error states with a `ValueNotifier`
- `ActionResource<T>` for handling async actions with loading, error, success, and retry states
- `HttpResource<T>` for HTTP-backed data sources with debounce, dependency reloading, and progress-aware loading states
- `PaginatedHttpResource<T>` for paged results and list pagination patterns, including inline start, loading, error, and end-of-list states
- `ComputedResource<T>` for derived values that automatically recompute when dependencies change
- `CesiumHttpService` for injectable HTTP clients with base options, interceptors, and reset support for testing
- `HttpResourceBase` to unify request execution, debounce behavior, dependency tracking, and HTTP progress updates
- `CesiumService` base type plus override/reset helpers for dependency injection and test isolation
- `ManagedListenerMixin` to make listener cleanup easier in stateful widgets
- Fluent listenable extensions for building widgets directly from resources and notifiers
- Centralized error handling via `Cesium.logError()` and `Cesium.setErrorHandler()`

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  cesium: ^2.0.0
```

Then import it in your Dart code:

```dart
import 'package:cesium/cesium.dart';
```

## Getting started

Cesium is designed to be used alongside standard Flutter widgets and state patterns. It does not replace `State`, `ChangeNotifier`, or `ValueNotifier`; instead, it adds useful wrappers around them for common app needs.

## Usage

### 1. Loading state with `FutureResource`

```dart
import 'package:cesium/cesium.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FutureResource<Map<String, dynamic>> profile = FutureResource(
    future: () => fetchProfile(),
  );

  Future<Map<String, dynamic>> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'name': 'Ada Lovelace'};
  }

  @override
  Widget build(BuildContext context) {
    return profile.pipe(
      loading: (_) => const Center(child: CircularProgressIndicator()),
      error: (_, error) => Center(child: Text('Error: $error')),
      value: (context, data) => Center(child: Text(data['name'])),
    );
  }

  @override
  void dispose() {
    profile.dispose();
    super.dispose();
  }
}
```

### 2. Derived values with `ComputedResource`

```dart
final items = ValueNotifier<List<String>>(['alpha', 'beta', 'gamma']);

final filteredItems = ComputedResource(
  () => items.value.where((item) => item.startsWith('a')).toList(),
  [items],
);

final widget = filteredItems.pipe((context, value) {
  return Text(value.join(', '));
});
```

When `items` changes, `filteredItems` recalculates automatically.

### 3. HTTP resources with `HttpResource`

```dart
final posts = HttpResource<List<Post>>(
  () => 'https://jsonplaceholder.typicode.com/posts',
  (json) => (json as List)
      .map((item) => Post.fromJson(item as Map<String, dynamic>))
      .toList(),
  debounceDuration: const Duration(milliseconds: 250),
);

final page = posts.pipeProgress(
  loading: (context, progress) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (progress > 0 && progress < 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${(progress * 100).toStringAsFixed(0)}%'),
          ),
      ],
    ),
  ),
  error: (_, error) => Text('Failed to load posts: $error'),
  value: (context, list) => ListView.builder(
    itemCount: list.length,
    itemBuilder: (_, index) => Text(list[index].title),
  ),
);
```

`HttpResourceBase` handles request execution, dependency-triggered reloads, debounce delays, and progress updates automatically.

### 4. Paginated resources

```dart
final comments = PaginatedHttpResource<Comment>(
  (_) => 'https://example.com/comments',
  (json) => Comment.fromJson(json),
  (page) => {'page': page},
  getMaxPages: (comment) => 5,
);

comments.loadMore();
```

`PaginatedHttpResource` keeps accumulating values across pages and supports inline header, loading, error, and end-of-list widgets through `pipePaginated(...)` when you want a list-style UI.

For example, you can add fixed widgets at the top of the list before the paginated items with `inlineStart`:

```dart
comments.pipePaginated(
  loading: (_, progress) => const Center(child: CircularProgressIndicator()),
  error: (_, error) => Center(child: Text('Error: $error')),
  inlineStart: (_) => [
    const Padding(
      padding: EdgeInsets.all(12),
      child: Text('Latest posts'),
    ),
  ],
  inlineLoading: (_, progress) => Padding(
    padding: const EdgeInsets.all(12),
    child: Center(child: CircularProgressIndicator(value: progress)),
  ),
  inlineError: (_, error) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text('Could not load more: $error'),
  ),
  inlineEnd: (_) => const Padding(
    padding: EdgeInsets.all(12),
    child: Text('You reached the end'),
  ),
  itemBuilder: (context, post, index) => ListTile(title: Text(post.title)),
  getItems: (post) => [post],
);
```

The `inlineStart` widgets render before the paginated items, while `inlineLoading`, `inlineError`, and `inlineEnd` remain appended after the loaded content in the same list.

### 5. Services and dependency injection

```dart
class AuthService extends CesiumService {
  bool loggedIn = false;

  @override
  void reset() {
    loggedIn = false;
    notifyListeners();
  }
}

void main() {
  register<AuthService>(() => AuthService());
  final auth = injectService<AuthService>();
}
```

You can also override a registered service for tests or environment-specific configuration:

```dart
registerOverride<AuthService>(() => TestAuthService());
final auth = injectService<AuthService>();
```

The shared `CesiumHttpService` is also injectable, which makes it easier to replace the default HTTP client or reset it between tests.

```dart
final http = ServiceProvider.withOverride(
  () => CesiumHttpService(),
  () => MockCesiumHttpService(),
);
```

### 6. Handling actions with `ActionResource<T>`

You can handle actions cleanly with action resource instead of tracking state manually

```dart
// 1. Declare an ActionResource (with optional value preservation or retry logic)
final loginAction = ActionResource<User>(
  perserveResult: true,
);

// 2. Trigger async work
loginAction.runNewAction(() => authService.login(email, password));

// 3. Bind UI & buttons directly to state
Widget build(BuildContext context) {
  return Column(
    children: [
      loginAction.pipe((context, state) => switch (state.status) {
        ActionStatus.idle => const Text('Please log in'),
        ActionStatus.loading => const CircularProgressIndicator(),
        ActionStatus.error => Text('Error: ${state.error}'),
        ActionStatus.done => Text('Welcome, ${state.value.name}!'),
      }),
      loginAction.pipeButton(
        buttonBuilder: (context, status, _) => ElevatedButton(
          onPressed: status == ActionStatus.loading ? null : submit,
          child: const Text('Submit'),
        ),
      ),
    ],
  );
}
```

### 7. Widget piping helpers

```dart
final notifier = ValueNotifier<String>('hello');

final widget = notifier.pipe(
  (context, value) => Text(value),
);
```

The library also includes `pipeChild` helpers for reusing a static child widget while only rebuilding the dynamic portion of the UI.

## Error handling

You can set a global error handler:

```dart
Cesium.setErrorHandler((error) {
  debugPrint('Cesium error: $error');
});
```

This is used by the async resource types when a request or computation fails, and it can also be triggered manually via `Cesium.logError(error)`.

## Why Cesium?

Cesium is a small, pragmatic toolkit for Flutter apps that want:

- clearer async UI states
- a lightweight alternative to larger state management frameworks
- minimal boilerplate for derived values and remote resources
- easy integration with standard Flutter `Listenable` patterns

## Additional information

- Repository: see the package source and tests in this workspace for the current implementation.
- Issues and feedback: open an issue in the package repository if available.
- Contributions are welcome for improvements, bug fixes, and additional helpers that fit the library's lightweight philosophy.
