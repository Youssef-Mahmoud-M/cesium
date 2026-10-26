import 'dart:async';

import 'package:cesium/src/managed_listener_mixin.dart';
import 'package:flutter/widgets.dart';

/// A wrapper class representing either a successfully emitted data value
/// or an error captured from a [Stream].
class StreamOption<T> {
  /// The data value emitted by the stream, if successful.
  final T? data;

  /// The error object captured from the stream, if an error occurred.
  final Object? error;

  /// Creates a [StreamOption] containing successful [data].
  StreamOption.data(this.data) : error = null;

  /// Creates a [StreamOption] containing an [error].
  StreamOption.error(this.error) : data = null;

  /// Whether this option represents an error rather than data.
  bool get hasError => error != null;
}

/// A widget that listens to a [Stream] and accumulates all emitted data events
/// and errors into a historical list, rebuilding whenever a new event arrives.
class AggregatedStreamBuilder<T> extends StatefulWidget {
  /// Creates an [AggregatedStreamBuilder].
  const AggregatedStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
  });

  /// The stream to listen to.
  final Stream<T> stream;

  /// Called for every build cycle to create the widget tree based on the
  /// accumulated data list and current connection state.
  final Widget Function(
    BuildContext context,
    List<StreamOption<T>> data,
    ConnectionState connectionState,
  )
  builder;

  @override
  State<AggregatedStreamBuilder<T>> createState() =>
      _AggregatedStreamBuilderState<T>();
}

class _AggregatedStreamBuilderState<T> extends State<AggregatedStreamBuilder<T>>
    with ManagedListenerMixin {
  /// The active subscription to the stream.
  late StreamSubscription<T> subscription;

  /// The accumulated history of data and error options emitted by the stream.
  final List<StreamOption<T>> data = [];

  /// The current connection state of the stream subscription.
  ConnectionState _connectionState = ConnectionState.waiting;

  @override
  void initState() {
    super.initState();
    _subscribeToStream(widget.stream);
  }

  @override
  void didUpdateWidget(AggregatedStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      cancelEarly(subscription);
      data.clear();
      _connectionState = ConnectionState.waiting;
      _subscribeToStream(widget.stream);
    }
  }

  /// Subscribes to the provided [stream], listening for data, errors,
  /// and completion events to update the accumulated state.
  void _subscribeToStream(Stream<T> stream) {
    subscription = listen(
      stream,
      onData: (newData) {
        setState(() {
          data.add(StreamOption.data(newData));
          _connectionState = ConnectionState.active;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        setState(() {
          data.add(StreamOption.error(error));
          _connectionState = ConnectionState.active;
        });
      },
      onDone: () {
        setState(() {
          _connectionState = ConnectionState.done;
        });
      },
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, data, _connectionState);
  }
}
