import 'dart:async';
import 'dart:isolate';

import 'package:isox/isox.dart';
import 'package:isox/src/config_implementation.dart';

class IsoxInstance<S> {
  // The isolate which is represented by this instance.
  final Isolate _isolate;

  // The ports to the Isolate.
  final SendPort _mtiPort;
  final ReceivePort _itmPort;

  // The itm subscription.
  final StreamSubscription<dynamic> _subscription;

  // Counter for the commands sent to the isolate.
  int _count = 0;

  final Map<int, Completer<dynamic>> _commandCompleter = {};

  IsoxInstance(
    this._isolate,
    this._mtiPort,
    this._itmPort,
    this._subscription,
  ) {
    _bindListener();
  }

  static Future<IsoxInstance<S>> loadIsolate<S>(IsoxInit<S> init) async {
    // Create a receive port for isolate to main communication.
    final itm = ReceivePort();

    // Start the actual isolate.
    final isolate = await Isolate.spawn(
      _loadIsoxIsolate,
      _IsoxIsolateInitializer<S>(init, itm.sendPort),
    );

    final completer = Completer<IsoxInstance<S>>();

    StreamSubscription subscription;
    subscription = itm.listen((message) {
      if (message is SendPort) {
        // Return the instance.
        completer.complete(
          IsoxInstance(isolate, message, itm, subscription),
        );
      } else if (message is _IsoxInitializingException) {
        completer.completeError(StateError(
          'Unable to initialize the isolate.',
        ));
      } else {
        // Just to be sure...
        completer.completeError(StateError(
          'Unable to process non-SendPort object as first received message.',
        ));
      }
    });

    return completer.future;
  }

  Future<O> run<I, O>(IsoxCommand<I, O, dynamic> command, I input) {
    final identifier = _count++;

    // Create the request object.
    final request = _IsoxInstanceRequest(
      identifier,
      command.name,
      input,
    );

    // Return immediately if no response is expected.
    if (!command.hasResponse) {
      return null;
    }

    // Create the completer for this command.
    final completer = Completer<O>();

    // Save the completer in the map.
    _commandCompleter[identifier] = completer;

    _mtiPort.send(request);

    // Return the future of the completer.
    return completer.future;
  }

  /// Will close the Isox instance. This basically kills the isolate and
  /// completes the pending requests with an error.
  Future<void> close() async {
    // Kill the Isolate.
    _isolate.kill();
    // Close the ports.
    _itmPort.close();
    await _subscription.cancel();

    // Complete all pending requests with an error.
    _commandCompleter.forEach((_, completer) {
      completer.completeError(IsoxInterruptionError());
    });
  }

  /// Will bind listeners to the isolate to main port.
  void _bindListener() {
    _subscription.onData((message) {
      if (message is _IsoxInstanceResponse) {
        final completer = _commandCompleter[message.identifier];

        completer.complete(message.commandOutput);

        _commandCompleter.remove(message.identifier);
      }
    });
  }
}

void _loadIsoxIsolate<S>(_IsoxIsolateInitializer<S> initializer) {
  // Create a new receive port for main to isolate.
  final mti = ReceivePort();
  final itm = initializer.sendPort;

  dynamic state;
  var config = InternalIsoxConfig();

  try {
    state = initializer.init(config);
  } catch (ex) {
    initializer.sendPort.send(_IsoxInitializingException());
    return;
  }

  // Send the created port to the main.
  initializer.sendPort.send(mti.sendPort);

  mti.listen((message) async {
    if (message is _IsoxInstanceRequest) {
      final cmd = config.commands[message.commandName];

      if (cmd != null) {
        try {
          final cmdResult = await cmd.run(message.commandInput, state);

          itm.send(_IsoxInstanceResponse(message.identifier, cmdResult));
        } catch (ex, stack) {
          if (config.errorHandler != null) {
            config.errorHandler(ex, stack);
          }
        }
      }
    }
  });
}

class _IsoxIsolateInitializer<S> {
  final IsoxInit<S> init;
  final SendPort sendPort;

  _IsoxIsolateInitializer(this.init, this.sendPort);
}

class _IsoxInstanceRequest {
  final int identifier;
  final String commandName;
  final dynamic commandInput;

  _IsoxInstanceRequest(this.identifier, this.commandName, this.commandInput);
}

class _IsoxInstanceResponse {
  final int identifier;
  final dynamic commandOutput;

  _IsoxInstanceResponse(this.identifier, this.commandOutput);
}

class _IsoxInitializingException {}

/// Exception which will be thrown when a isolate has been killed before
/// completing pending requests.
class IsoxInterruptionError implements Exception {}
