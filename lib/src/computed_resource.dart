import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:flutter/foundation.dart';

class ComputedResource<T> extends ValueNotifier<T> {
  final T Function() _computation;
  final Iterable<Listenable> _dependencies;
  final Duration? debounceDuration;
  Timer? timer;
  ComputedResource(
    this._computation,
    this._dependencies, [
    this.debounceDuration,
  ]) : super(
         (() {
           try {
             return _computation();
           } catch (e) {
             Cesium.logError(e);
             rethrow;
           }
         })(),
       ) {
    for (var dependency in _dependencies) {
      dependency.addListener(_dependencyListener);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var dependency in _dependencies) {
      dependency.removeListener(_dependencyListener);
    }
  }

  void _handleComputation({bool useDebounce = true}) {
    if (!useDebounce || debounceDuration == null) {
      try {
        value = _computation();
      } catch (e) {
        Cesium.logError(e);
      }
      return;
    }

    timer?.cancel();
    timer = Timer(debounceDuration!, () {
      _handleComputation(useDebounce: false);
    });
  }

  void _dependencyListener() {
    _handleComputation();
  }
}
