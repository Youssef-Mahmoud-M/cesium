import 'package:cesium/src/error_logger.dart';
import 'package:async/async.dart';
import 'package:flutter/widgets.dart';

/// Represents the current state of a `FutureResource`.
class FutureResourceValue<T> {
  /// Whether the resource is currently loading.
  final bool isLoading;

  /// Last successful value, if any.
  final T? value;

  /// The last error that occurred, if any.
  final Object? error;

  /// Construct a loading state with an optional current value.
  const FutureResourceValue([T? currentValue])
    : isLoading = true,
      value = currentValue,
      error = null;

  /// Construct a successful value state.
  const FutureResourceValue.value(T this.value)
    : isLoading = false,
      error = null;

  /// Construct an error state with an optional previous value.
  const FutureResourceValue.error(Object this.error, [T? currentValue])
    : isLoading = false,
      value = currentValue;
}

/// An observable wrapper around an asynchronous operation that supports
/// cancellation and an optional option to preserve the last successful
/// result while the new operation runs.
class FutureResource<T> extends ValueNotifier<FutureResourceValue<T>> {
  final bool _perserveResult;
  CancelableOperation<T>? _operation;
  bool _isDisposed = false;

  /// Whether the resource is currently loading.
  bool get isLoading => value.isLoading;

  /// The current error, if any.
  Object? get error => value.error;

  /// The most recent successful result, if available.
  T? get result => value.value;

  /// Create a `FutureResource`. If a `future` is provided it will be
  /// started immediately.
  FutureResource(Future<T> Function()? future, [this._perserveResult = false])
    : super(const FutureResourceValue()) {
    if (future != null) {
      _startOperation(future());
    }
  }

  void _startOperation(Future<T> future) {
    _operation = CancelableOperation.fromFuture(
      future,
      onCancel: () {
        if (!_isDisposed) {
          value = FutureResourceValue(_perserveResult ? result : null);
        }
      },
    );

    _operation!.value
        .then((val) {
          if (!_isDisposed && !(_operation?.isCanceled ?? true)) {
            value = FutureResourceValue.value(val);
          }
        })
        .catchError((e) {
          if (!_isDisposed && !(_operation?.isCanceled ?? true)) {
            value = FutureResourceValue.error(
              e,
              _perserveResult ? result : null,
            );
          }
          Cesium.logError(e);
        });
  }

  /// Cancel the currently running operation, if any.
  void cancel() {
    _operation?.cancel();
  }

  /// Start a new asynchronous operation, cancelling any prior one. If
  /// `_perserveResult` is true the previous successful result is kept
  /// visible while the new operation runs.
  /// if `optimisticValue` is passed it will be the value in result until a new value arrives
  void runNewFuture(Future<T> Function() newFuture, [T? optimisticValue]) {
    if (value.isLoading) {
      cancel();
    }
    _operation?.cancel();
    value = FutureResourceValue(
      optimisticValue ?? (_perserveResult ? result : null),
    );
    _startOperation(newFuture());
  }

  @override
  /// Dispose the resource and cancel any active operation.
  void dispose() {
    _isDisposed = true;
    _operation?.cancel();
    super.dispose();
  }

  /// Build widgets that react to the current loading / error / value
  /// states of this resource.
  Widget pipe({
    required Widget Function(BuildContext context) loading,
    required Widget Function(BuildContext, Object) error,
    required Widget Function(BuildContext, T value) value,
  }) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (context, val, _) {
        if (result != null) {
          return value(context, result as T);
        }
        if (val.isLoading) return loading(context);
        if (val.error != null) return error(context, val.error!);
        return value(context, val.value as T);
      },
    );
  }
}
