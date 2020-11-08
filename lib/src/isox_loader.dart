import 'dart:isolate';

import 'package:isox/src/isox_command_registry.dart';
import 'package:isox/src/isox_consumer.dart';
import 'package:isox/src/isox_instance.dart';

typedef IsoxIsolateInit<S> = S Function(IsoxRegistry<S> consumer);

class IsoxLoader {
  Future<IsoxInstance<S>> loadIsolate<S>(
    IsoxIsolateInit<S> initFunction,
  ) async {
    // Create a receive port for isolate to main communication.
    final itm = ReceivePort();

    // Start the actual isolate.
    final isolate = await Isolate.spawn(_loadIsoxIsolate, itm.sendPort);

    // Wait for the first item of the itm port.
    final first = await itm.first;

    if (first is SendPort) {
      // Return the instance.
      return IsoxInstance(isolate, first, itm);
    } else {
      // Just to be sure...
      throw StateError(
          'Unable to process non-SendPort object as first received message.');
    }
  }
}

void _loadIsoxIsolate(SendPort itm) {
  // Create a new receive port for main to isolate.
  final mti = ReceivePort();

  // Send the created port to the main.
  itm.send(mti.sendPort);
}
