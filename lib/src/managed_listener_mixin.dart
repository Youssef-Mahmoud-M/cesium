import 'package:flutter/widgets.dart';

/// Mixin to manage `Listenable` listeners and automatically remove them
/// when the `State` is disposed.
mixin ManagedListenerMixin<T extends StatefulWidget> on State<T> {
  final Map<Listenable, List<void Function()>> _addedListeners = {};
  final Set<ChangeNotifier> _managedListenables = {};

  /// Add a listener to [listenable] and track it so it is removed on
  /// `dispose()`.
  void addListener(Listenable listenable, void Function() listener) {
    listenable.addListener(listener);
    _addedListeners[listenable] ??= [];
    _addedListeners[listenable]!.add(listener);
  }

  /// Remove a tracked listener manually before state disposal.
  bool removeListener(Listenable listenable, void Function() listener) {
    final listeners = _addedListeners[listenable];
    if (listeners != null && listeners.remove(listener)) {
      listenable.removeListener(listener);
      if (listeners.isEmpty) {
        _addedListeners.remove(listenable);
      }
      return true;
    }
    return false;
  }

  /// Track a [ChangeNotifier] to be automatically disposed on widget disposal
  N manage<N extends ChangeNotifier>(N listenable) {
    _managedListenables.add(listenable);
    return listenable;
  }

  @override
  void dispose() {
    for (final entry in _addedListeners.entries) {
      for (final listener in entry.value) {
        entry.key.removeListener(listener);
      }
    }
    _addedListeners.clear();

    for (final listenable in _managedListenables) {
      listenable.dispose();
    }
    _managedListenables.clear();

    super.dispose();
  }
}
