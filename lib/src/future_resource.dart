import 'package:cesium/src/error_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:flutter/widgets.dart';

class FutureResourceValue<T> {
  final bool isLoading;
  final T? value;
  final Object? error;

  const FutureResourceValue([T? currentValue])
    : isLoading = true,
      value = currentValue,
      error = null;
  const FutureResourceValue.value(T this.value)
    : isLoading = false,
      error = null;
  const FutureResourceValue.error(Object this.error, [T? currentValue])
    : isLoading = false,
      value = currentValue;
}

class FutureResource<T> extends ValueNotifier<FutureResourceValue<T>> {
  final bool _perserveResult;
  CancelableOperation<T>? _operation;
  bool _isDisposed = false;
  bool get isLoading => value.isLoading;
  Object? get error => value.error;
  T? get result => value.value;

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

  void cancel() {
    _operation?.cancel();
  }

  void runNewFuture(Future<T> Function() newFuture) {
    if (value.isLoading) {
      cancel();
    }
    _operation?.cancel();
    value = FutureResourceValue(_perserveResult ? result : null);
    _startOperation(newFuture());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _operation?.cancel();
    super.dispose();
  }

  Widget pipe({
    required Widget Function(BuildContext context) loading,
    required Widget Function(BuildContext, Object) error,
    required Widget Function(BuildContext, T value) value,
  }) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (context, val, _) {
        if (result != null && _perserveResult) {
          return value(context, result as T);
        }
        if (val.isLoading) return loading(context);
        if (val.error != null) return error(context, val.error!);
        return value(context, val.value as T);
      },
    );
  }
}
