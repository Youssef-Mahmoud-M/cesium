import 'package:flutter/widgets.dart';

mixin ManagedListenerMixin<T extends StatefulWidget> on State<T> {
  final Map<Listenable, List<void Function()>> _addedListeners = {};

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
