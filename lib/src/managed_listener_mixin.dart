import 'package:flutter/widgets.dart';

/// Mixin to manage `Listenable` listeners and automatically remove them
/// when the `State` is disposed.
mixin ManagedListenerMixin<T extends StatefulWidget> on State<T> {
  final Map<Listenable, List<void Function()>> _addedListeners = {};

  /// Add a listener to [listenable] and track it so it is removed on
  /// `dispose()`.
  void addListener(Listenable listenable, void Function() listener) {
    listenable.addListener(listener);
    _addedListeners[listenable] ??= [];
    _addedListeners[listenable]!.add(listener);
  }

  @override
  void dispose() {
    _addedListeners.forEach((l, listeners) {
      for (var listener in listeners) {
        l.removeListener(listener);
      }
    });
    super.dispose();
  }
}
