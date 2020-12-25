import 'dart:async';
import 'dart:isolate';

import 'package:isox/src/instance.dart';
import 'package:isox/src/typedefs.dart';

/// Defines a group which can manage multiple Isox instances.
/// This is defines the public API.
abstract class IsoxGroup {
  /// Will load a new [IsoxGroup].
  static Future<IsoxGroup> loadGroup({String debugName}) {
    return InternalIsoxGroup.loadGroup(debugName: debugName);
  }

  // Will dispose this group. This will implicitly also dispose all attached
  // Isox instances.
  Future<void> close();
}

/// Defines a group which provides methods to attach new instance. (Also detach)
/// This is not part of the public API!
abstract class AttachableIsoxGroup extends IsoxGroup {
  Future<void> attachInstance(
    void Function(IsoxIsolateInitializer) loader,
    IsoxIsolateInitializer initializer,
  );
}

/// Implementation of a group which is not part of the public API.
/// This provides methods for internal registration of the actual instance.
class InternalIsoxGroup extends AttachableIsoxGroup {
  /// The isolate which is used by this group. This must never be null.
  final Isolate _isolate;

  /// The ports for the management of this group. Both must never be null.
  final SendPort mtiPort;
  final ReceivePort itmPort;

  final StreamSubscription itmSubscription;

  InternalIsoxGroup._(
    this._isolate,
    this.mtiPort,
    this.itmPort,
    this.itmSubscription,
  );

  /// Will load the [IsoxGroup] with no configuration.
  static Future<InternalIsoxGroup> loadGroup({String debugName}) async {
    // The completer which will be completed when the group has been fully loaded.
    final completer = Completer<IsoxGroup>();

    // Create the port for the isolate-to-main communication.
    final itmPort = ReceivePort();

    // Spawn the actual isolate in paused state.
    final isolate = await Isolate.spawn(
      _initIsoxGroup,
      itmPort.sendPort,
      debugName: debugName ?? 'IsoxGroup',
      paused: true,
    );

    StreamSubscription subscription;

    // Star listening on the port.
    subscription = itmPort.listen((message) {
      if (message is SendPort) {
        completer.complete(
          InternalIsoxGroup._(
            isolate,
            message,
            itmPort,
            subscription,
          ),
        );
      }
      // ???
    });

    isolate.resume(isolate.pauseCapability);

    // Return the future of the completer.
    return completer.future;
  }

  @override
  Future<void> attachInstance(
    IsoxLoader loader,
    IsoxIsolateInitializer initializer,
  ) async {
    final request = _IsoxGroupRegisterRequest(initializer, loader);

    mtiPort.send(request);
  }

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }
}

void _initIsoxGroup(SendPort port) {
  // Define the ports for the communication.
  final mtiPort = ReceivePort();
  final itmPort = port;

  // Send the main-to-isolate port to the main process.
  itmPort.send(mtiPort.sendPort);

  mtiPort.listen((message) {
    if (message is _IsoxGroupRegisterRequest) {
      message.loader(message.initializer);
    }
  });
}

class _IsoxGroupRegisterRequest {
  final void Function(IsoxIsolateInitializer) loader;
  final IsoxIsolateInitializer initializer;

  _IsoxGroupRegisterRequest(this.initializer, this.loader);
}
