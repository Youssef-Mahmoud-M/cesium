import 'package:cesium/cesium.dart';
import 'package:flutter/material.dart';

/// Mixin to manage `Listenable` listeners and automatically remove them
/// when the `State` is disposed.
mixin ManagedListenerMixin<W extends StatefulWidget> on State<W> {
  final Map<Listenable, List<VoidCallback>> _addedListeners = {};
  final Set<ChangeNotifier> _managedListenables = {};
  final Set<AnimationController> _managedAnimations = {};

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
  T manage<T extends ChangeNotifier>(T listenable) {
    _managedListenables.add(listenable);
    return listenable;
  }

  /// Track a [AnimationController] to be automatically disposed on widget disposal
  T manageAnimation<T extends AnimationController>(T animation) {
    _managedAnimations.add(animation);
    return animation;
  }

  /// A more concise way to write a managed [ValueNotifier]
  ValueNotifier<T> value<T>(T value) {
    return manage(ValueNotifier<T>(value));
  }

  /// A more concise way to write a managed [TextEditingController]
  TextEditingController textController({String? text}) {
    return manage(TextEditingController(text: text));
  }

  /// A more concise way to write a managed [ScrollController]
  ScrollController scrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    ScrollControllerCallback? onAttach,
    ScrollControllerCallback? onDetach,
  }) {
    return manage(
      ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
        onAttach: onAttach,
        onDetach: onDetach,
      ),
    );
  }

  /// A more concise way to write a managed [PageController]
  PageController pageController({
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    ScrollControllerCallback? onAttach,
    ScrollControllerCallback? onDetach,
  }) {
    return manage(
      PageController(
        initialPage: initialPage,
        keepPage: keepPage,
        viewportFraction: viewportFraction,
        onAttach: onAttach,
        onDetach: onDetach,
      ),
    );
  }

  /// A more concise way to write a managed [AnimationController]
  AnimationController animationController({
    required TickerProvider vsync,
    double? value,
    String? debugLabel,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    return manageAnimation(
      AnimationController(
        vsync: vsync,
        value: value,
        debugLabel: debugLabel,
        duration: duration,
        reverseDuration: reverseDuration,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
      ),
    );
  }

  /// A more concise way to write a managed [FocusNode]
  FocusNode focusNode({
    String? debugLabel,
    @Deprecated(
      'Use FocusOnKeyEventCallback instead. '
      'This feature was deprecated after v3.18.0-2.0.pre.',
    )
    FocusOnKeyCallback? onKey,
    FocusOnKeyEventCallback? onKeyEvent,
    bool skipTraversal = false,
    bool canRequestFocus = true,
    bool descendantsAreFocusable = true,
    bool descendantsAreTraversable = true,
  }) {
    return manage(
      FocusNode(
        debugLabel: debugLabel,
        // ignore: deprecated_member_use
        onKey: onKey,
        onKeyEvent: onKeyEvent,
        skipTraversal: skipTraversal,
        canRequestFocus: canRequestFocus,
        descendantsAreFocusable: descendantsAreFocusable,
        descendantsAreTraversable: descendantsAreTraversable,
      ),
    );
  }

  /// A more concise way to write a managed [TabController]
  TabController tabController({
    int initialIndex = 0,
    Duration? animationDuration,
    required int length,
    required TickerProvider vsync,
  }) {
    return manage(
      TabController(
        initialIndex: initialIndex,
        animationDuration: animationDuration,
        length: length,
        vsync: vsync,
      ),
    );
  }

  ///A more concise way to write a managed [TransformationController]
  TransformationController transformationController([Matrix4? value]) {
    return manage(TransformationController(value));
  }

  /// A more concise way to write a managed [UndoHistoryController]
  UndoHistoryController undoHistoryController({UndoHistoryValue? value}) {
    return manage(UndoHistoryController(value: value));
  }

  /// A concise way to write a managed [FutureResource]
  FutureResource<T> futureResource<T>({
    Future<T> Function()? future,
    bool perserveResult = false,
    Future<T> Function(Object error, int attempt)? retryOnError,
  }) {
    return manage(
      FutureResource<T>(
        future: future,
        perserveResult: perserveResult,
        retryOnError: retryOnError,
      ),
    );
  }

  /// A concise way to write a managed [HttpResource]
  HttpResource<T> httpResource<T>(
    String Function() urlBuilder,
    T Function(dynamic data) transform, {
    Map<String, dynamic> Function()? queryParametersBuilder,
    Iterable<Listenable> dependecies = const [],
    Duration? debounceDuration,
    Map<String, String> headers = const {},
    int maxRetryAttempts = 0,
  }) {
    return manage(
      HttpResource<T>(
        urlBuilder,
        transform,
        queryParametersBuilder: queryParametersBuilder,
        dependecies: dependecies,
        debounceDuration: debounceDuration,
        headers: headers,
        maxRetryAttempts: maxRetryAttempts,
      ),
    );
  }

  /// A concise way to write a managed [PaginatedHttpResource]
  PaginatedHttpResource<T> paginatedHttpResource<T>(
    String Function(int page) urlBuilder,
    T Function(dynamic data) transform,
    Map<String, dynamic> Function(int page) queryParamatersBuilder, {
    Iterable<Listenable> dependecies = const [],
    Duration? debounceDuration,
    Map<String, String> headers = const {},
    int maxRetryAttempts = 0,
    int Function(T)? getMaxPages,
    int startPage = 1,
  }) {
    return manage(
      PaginatedHttpResource<T>(
        urlBuilder,
        transform,
        queryParamatersBuilder,
        dependecies: dependecies,
        debounceDuration: debounceDuration,
        headers: headers,
        maxRetryAttempts: maxRetryAttempts,
        getMaxPages: getMaxPages,
        startPage: startPage,
      ),
    );
  }

  /// A concise way to write a managed [ActionResource]
  ActionResource<T> actionResource<T>({
    bool perserveResult = false,
    Future<T> Function(Object error, int attempt)? retryOnError,
    Future<T> Function()? future,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
  }) {
    return manage(
      ActionResource<T>(
        perserveResult: perserveResult,
        retryOnError: retryOnError,
        future: future,
        onSuccess: onSuccess,
        onFailure: onFailure,
      ),
    );
  }

  /// A concise way to write a managed [ComputedResource]
  ComputedResource<T> computedResource<T>(
    T Function() computation,
    Iterable<Listenable> dependencies, {
    Duration? debounceDuration,
  }) {
    return manage(
      ComputedResource<T>(
        computation,
        dependencies,
        debounceDuration: debounceDuration,
      ),
    );
  }

  @override
  @mustCallSuper
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

    for (final animation in _managedAnimations) {
      animation.dispose();
    }
    _managedAnimations.clear();

    super.dispose();
  }
}
