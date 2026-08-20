import 'package:cesium/src/error_logger.dart';
import 'package:async/async.dart';
import 'package:flutter/widgets.dart';

/// Enum representing the current status of the action
enum ActionStatus {
  /// When the action is loading
  loading,

  /// When currently idle
  idle,

  /// When the action fails
  error,

  /// When the action succeeds
  done,
}

/// Represents the current state of a `ActionResource`.
class ActionResourceValue<T> {
  /// The current status of the action
  final ActionStatus status;

  /// Last successful value, if any.
  final T? value;

  /// The last error that occurred, if any.
  final Object? error;

  /// Construct an idle state with an optional current value.
  const ActionResourceValue([T? currentValue])
    : status = ActionStatus.idle,
      value = currentValue,
      error = null;

  /// Construct a loading state with an optional current value.
  const ActionResourceValue.loading([T? currentValue])
    : status = ActionStatus.loading,
      value = currentValue,
      error = null;

  /// Construct a successful value state.
  const ActionResourceValue.value(T this.value)
    : status = ActionStatus.done,
      error = null;

  /// Construct an error state with an optional previous value.
  const ActionResourceValue.error(Object this.error, [T? currentValue])
    : status = ActionStatus.error,
      value = currentValue;
}

/// An observable wrapper around an asynchronous operation that supports
/// cancellation and an optional option to preserve the last successful
/// result while the new operation runs.
class ActionResource<T> extends ValueNotifier<ActionResourceValue<T>> {
  final bool _perserveResult;
  int _currentAttempt = 0;
  CancelableOperation<T>? _operation;
  bool _isDisposed = false;
  bool _isRetrying = false;

  /// A method that is called to retry an action when an error occurs,
  /// if it returns null the last error will used in the error state
  Future<T>? Function(Object error, int attempt)? retryActionOnError;

  /// Whether the resource is currently loading.
  ActionStatus get status => value.status;

  /// The current error, if any.
  Object? get error => value.error;

  /// The most recent successful result, if available.
  T? get result => value.value;

  /// Create an `ActionResource`. If a `future` is provided it will be
  /// started immediately.
  ActionResource([
    this._perserveResult = false,
    this.retryActionOnError,
    Future<T> Function()? future,
  ]) : super(
         future == null
             ? const ActionResourceValue()
             : const ActionResourceValue.loading(),
       ) {
    if (future != null) {
      _startOperation(future());
    }
  }

  void _startOperation(Future<T> future) {
    _operation = CancelableOperation.fromFuture(
      future,
      onCancel: () {
        if (!_isDisposed && !_isRetrying) {
          value = ActionResourceValue(_perserveResult ? result : null);
        }
      },
    );

    _operation!.value
        .then((val) {
          if (!_isDisposed && !(_operation?.isCanceled ?? true)) {
            _currentAttempt = 0;
            value = ActionResourceValue.value(val);
          }
        })
        .catchError((e) {
          Cesium.logError(e);
          if (!_isDisposed && !(_operation?.isCanceled ?? true)) {
            _currentAttempt++;
            final newAction = retryActionOnError?.call(e, _currentAttempt);

            if (newAction != null) {
              _executeReattempt(() => newAction);
              return;
            }

            _currentAttempt = 0; // Reset on final failure
            value = ActionResourceValue.error(
              e,
              _perserveResult ? result : null,
            );
          }
        });
  }

  void _executeReattempt(Future<T> Function() newFuture) {
    _isRetrying = true;
    _operation?.cancel();
    _isRetrying = false;
    _startOperation(newFuture());
  }

  /// Cancel the currently running operation, if any.
  void cancel() {
    _operation?.cancel();
  }

  /// Start a new asynchronous operation, cancelling any prior one. If
  /// `_perserveResult` is true the previous successful result is kept
  /// visible while the new operation runs.
  /// if `optimisticValue` is passed it will be the value in result until a new value arrives
  void runNewAction(Future<T> Function() newAction, [T? optimisticValue]) {
    _currentAttempt = 0;
    _operation?.cancel();
    value = ActionResourceValue.loading(
      optimisticValue ?? (_perserveResult ? result : null),
    );
    _startOperation(newAction());
  }

  @override
  /// Dispose the resource and cancel any active operation.
  void dispose() {
    _isDisposed = true;
    _operation?.cancel();
    super.dispose();
  }

  /// Convenience widget to pipe a button with a loading and idle state
  Widget pipeButton({
    required Widget Function(BuildContext, ActionStatus, Widget?) buttonBuilder,
    Widget? child,
  }) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (context, value, child) =>
          buttonBuilder(context, value.status, child),
      child: child,
    );
  }
}
