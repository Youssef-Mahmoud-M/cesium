import 'package:cesium/cesium.dart';
import 'package:flutter/widgets.dart';

/// Extensions to make it concise to render `ValueNotifier` values in the
/// widget tree.
extension CesiumValueNotifierX<T> on ValueNotifier<T> {
  /// Build a `ValueListenableBuilder` wired to this `ValueNotifier`.
  ValueListenableBuilder<T> pipe(
    Widget Function(BuildContext context, T value) builder,
  ) {
    return ValueListenableBuilder<T>(
      valueListenable: this,
      builder: (context, value, _) => builder(context, value),
    );
  }

  /// Like `pipe` but forwards a static `child` to the builder.
  ValueListenableBuilder<T> pipeChild(
    Widget Function(BuildContext context, T value, Widget? child) builder, {
    Widget? child,
  }) {
    return ValueListenableBuilder<T>(
      valueListenable: this,
      builder: builder,
      child: child,
    );
  }
}

/// Extensions to make it concise to render `ValueNotifier<FutureResourceValue<T>>` values in the
/// widget tree.
extension CesiumValueNotifierFutureResourceX<T>
    on ValueNotifier<FutureResourceValue<T>> {
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
        if (val.isLoading) return loading(context);
        if (val.error != null) return error(context, val.error!);
        return value(context, val.value as T);
      },
    );
  }
}

/// Convenience builders for generic `Listenable` objects.
extension CesiumListenableX on Listenable {
  /// Build a `ListenableBuilder` for this `Listenable`.
  ListenableBuilder pipe(Widget Function(BuildContext context) builder) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) => builder(context),
    );
  }

  /// Like `pipe` but supplies a static `child` to the builder.
  ListenableBuilder pipeChild(
    Widget Function(BuildContext context, Widget? child) builder, {
    Widget? child,
  }) {
    return ListenableBuilder(listenable: this, builder: builder, child: child);
  }
}

/// Helpers for a list of `Listenable` objects merged into a single
/// `Listenable` via `Listenable.merge`.
extension CesiumListenableListX on List<Listenable> {
  /// Build a `ListenableBuilder` that listens to the merged
  /// `Listenable` from this list.
  ListenableBuilder pipe(Widget Function(BuildContext context) builder) {
    return ListenableBuilder(
      listenable: Listenable.merge(this),
      builder: (context, _) => builder(context),
    );
  }

  /// Like [pipe] but forwards a static `child` to the builder.
  ListenableBuilder pipeChild(
    Widget Function(BuildContext context, Widget? child) builder, {
    Widget? child,
  }) {
    return ListenableBuilder(
      listenable: Listenable.merge(this),
      builder: builder,
      child: child,
    );
  }
}

/// Extensions to make it concise to render `Stream` values in the widget tree.
extension CesiumStreamX<T> on Stream<T> {
  /// Builds a `StreamBuilder` that separates handling based on the stream's
  /// current [ConnectionState], providing explicit builder callbacks for
  /// [ConnectionState.none], [ConnectionState.waiting], [ConnectionState.active],
  /// and [ConnectionState.done].
  ///
  /// [noneBuilder] falls back to [waitingBuilder] and [doneBuilder] falls back
  /// to [activeBuilder] when they are not provided.
  StreamBuilder<T> pipeSeparated({
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget Function(BuildContext, T?)? noneBuilder,
    required Widget Function(BuildContext, T?) waitingBuilder,
    required Widget Function(BuildContext, T?) activeBuilder,
    Widget Function(BuildContext, T?)? doneBuilder,
  }) {
    final none = noneBuilder ?? waitingBuilder;
    final done = doneBuilder ?? activeBuilder;
    return StreamBuilder<T>(
      stream: this,
      builder: (context, snapshot) {
        if (snapshot.hasError && errorBuilder != null) {
          return errorBuilder(context, snapshot.error);
        }
        return switch (snapshot.connectionState) {
          ConnectionState.none => none(context, snapshot.data),
          ConnectionState.waiting => waitingBuilder(context, snapshot.data),
          ConnectionState.active => activeBuilder(context, snapshot.data),
          ConnectionState.done => done(context, snapshot.data),
        };
      },
    );
  }

  /// Build a standard `StreamBuilder` wired to this stream.
  StreamBuilder<T> pipeSingle(
    Widget Function(BuildContext, AsyncSnapshot<T>) builder,
  ) {
    return StreamBuilder<T>(stream: this, builder: builder);
  }

  /// Build an `AggregatedStreamBuilder` that accumulates all emitted data and errors
  /// from this stream into a historical list.
  AggregatedStreamBuilder<T> pipeAggregated(
    Widget Function(
      BuildContext context,
      List<StreamOption<T>> data,
      ConnectionState connectionState,
    )
    builder,
  ) {
    return AggregatedStreamBuilder<T>(stream: this, builder: builder);
  }
}
