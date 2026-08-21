import 'dart:async';

import 'package:cesium/cesium.dart';
import 'package:flutter/foundation.dart';

/// A `ValueNotifier` whose value is computed from other `Listenable`
/// dependencies.
///
/// The provided computation is run initially and whenever any dependency
/// notifies. Optionally a debounce duration can be used to throttle
/// recomputations.
class ComputedResource<T> extends ValueNotifier<T> {
  final T Function() _computation;
  final Iterable<Listenable> _dependencies;

  /// Optional debounce used to throttle recomputation.
  final Duration? debounceDuration;

  /// Active debounce timer when a debounced recomputation is scheduled.
  Timer? timer;

  /// Create a `ComputedResource`.
  ///
  /// The initial value is computed immediately from `_computation`. The
  /// resource will re-run the computation whenever any dependency
  /// notifies. Optionally pass a `debounceDuration` to throttle updates.
  ComputedResource(
    this._computation,
    this._dependencies, {
    this.debounceDuration,
  }) : super(
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
