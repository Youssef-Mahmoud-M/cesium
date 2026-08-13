import 'package:flutter/widgets.dart';

extension CesiumValueNotifierX<T> on ValueNotifier<T> {
  ValueListenableBuilder<T> pipe(
    Widget Function(BuildContext context, T value) builder,
  ) {
    return ValueListenableBuilder<T>(
      valueListenable: this,
      builder: (context, value, _) => builder(context, value),
    );
  }

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

extension CesiumListenableX on Listenable {
  ListenableBuilder pipe(Widget Function(BuildContext context) builder) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) => builder(context),
    );
  }

  ListenableBuilder pipeChild(
    Widget Function(BuildContext context, Widget? child) builder, {
    Widget? child,
  }) {
    return ListenableBuilder(listenable: this, builder: builder, child: child);
  }
}

extension CesiumListenableListX on List<Listenable> {
  ListenableBuilder pipe(Widget Function(BuildContext context) builder) {
    return ListenableBuilder(
      listenable: Listenable.merge(this),
      builder: (context, _) => builder(context),
    );
  }

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
