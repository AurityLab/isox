import 'dart:async';
import 'dart:isolate';

import 'package:isox/isox.dart';

class IsoxGroup {
  /// The isolate which is used by this group. This must never be null.
  final Isolate _isolate;

  /// The ports for the management of this group. Both must never be null.
  final SendPort managementMTIPort;
  final ReceivePort managementITMPort;

  final StreamSubscription managementITMSubscription;

  IsoxGroup(
    this._isolate,
    this.managementMTIPort,
    this.managementITMPort,
    this.managementITMSubscription,
  );

  /// Will load the [IsoxGroup] with no configuration.
  static Future<IsoxGroup> loadGroup() async {
    // The completer which will be completed when the group has been fully loaded.
    final completer = Completer<IsoxGroup>();

    // Create the port for the isolate-to-main communication.
    final itmPort = ReceivePort();

    // Spawn the actual isolate in paused state.
    final isolate = await Isolate.spawn(
      _initIsoxGroup,
      itmPort.sendPort,
      paused: true,
    );

    StreamSubscription subscription;

    // Star listening on the port.
    subscription = itmPort.listen((message) {
      if (message is SendPort) {
        completer.complete(
          IsoxGroup(
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

  Future<void> registerInstance(
    void Function(IsoxIsolateInitializer) loader,
    IsoxIsolateInitializer initializer,
  ) {
    final request = _IsoxGroupRegisterRequest(initializer, loader);

    managementMTIPort.send(request);
  }
}

void _initIsoxGroup(SendPort port) {
  // Define the ports for the communication.
  final mtiPort = ReceivePort();
  final itmPort = port;

  // Send the main-to-isolate port to the main process.
  itmPort.send(mtiPort.sendPort);

  mtiPort.listen((message) {
    if(message is _IsoxGroupRegisterRequest) {
      message.loader(message.initializer);
    }
  });
}

class _IsoxGroupRegisterRequest {
  final void Function(IsoxIsolateInitializer) loader;
  final IsoxIsolateInitializer initializer;

  _IsoxGroupRegisterRequest(this.initializer, this.loader);
}
