import 'dart:async';
import 'dart:isolate';

import 'package:isox/isox.dart';
import 'package:isox/src/config_implementation.dart';
import 'package:isox/src/exceptions.dart';

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
    // Define the completer for the initialization of this instance.
    // The future of this completer will later on be returned by this method.
    final completer = Completer<IsoxInstance<S>>();

    // Create a receive port for isolate to main communication.
    final itm = ReceivePort();

    // Start the actual isolate in paused state to initialize all listeners
    // for the ports.
    final isolate = await Isolate.spawn(
      _loadIsoxIsolate,
      _IsoxIsolateInitializer<S>(init, itm.sendPort),
      paused: true,
    );

    // Holds the subscription for the isolate-to-main port.
    StreamSubscription itmSubscription;

    // Add a listener to the isolate-to-main port.
    itmSubscription = itm.listen((message) {
      if (message is SendPort) {
        // Create the instance and send it to the completer.
        completer.complete(
          IsoxInstance(
            isolate,
            message,
            itm,
            itmSubscription,
          ),
        );
      } else if (message is _IsoxErrorContainer) {
        // If the completer is not yet completed, then this exception is an initialization exception.
        if (!completer.isCompleted) {
          final exception = IsoxInitializationException(
            message.message,
            StackTrace.fromString(message.stackTrace),
          );

          completer.completeError(exception);
          itmSubscription.cancel();
        }
      } else {
        // Just to be sure...
        completer.completeError(StateError(
          'Unable to process non-SendPort object as first received message.',
        ));
      }
    });

    isolate.resume(isolate.pauseCapability);

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
      completer.completeError(IsoxInterruptionException());
    });
  }

  /// Will bind listeners to the isolate to main port.
  void _bindListener() {
    _subscription.onData((message) {
      if (message is _IsoxInstanceResponse) {
        final completer = _commandCompleter[message.identifier];

        completer.complete(message.commandOutput);

        _commandCompleter.remove(message.identifier);
      } else if (message is _IsoxErrorContainer) {
        final completer = _commandCompleter[message.identifier];

        final exception = IsoxWrappedException(
          message.message,
          StackTrace.fromString(message.stackTrace),
        );

        completer.completeError(exception);

        _commandCompleter.remove(message.identifier);
      }
    });
  }
}

void _loadIsoxIsolate<S>(_IsoxIsolateInitializer<S> initializer) {
  // Create a new receive port for main to isolate.
  final mti = ReceivePort();
  final itm = initializer.sendPort;

  var config = InternalIsoxConfig();

  dynamic state;
  try {
    state = runZonedGuarded(() {
      return initializer.init(config);
    }, (error, stack) {
      initializer.sendPort.send(_IsoxErrorContainer(
        null,
        error?.toString(),
        stack?.toString(),
      ));

      // Throw the error to
      throw error;
    });
  } catch (_) {
    return;
  }

  // Send the created port to the main.
  initializer.sendPort.send(mti.sendPort);

  mti.listen((message) async {
    if (message is _IsoxInstanceRequest) {
      final cmd = config.commands[message.commandName];

      if (cmd != null) {
        try {
          final cmdResult = await runZonedGuarded(() async {
            return await cmd.run(message.commandInput, state);
          }, (error, stack) {
            itm.send(_IsoxErrorContainer(
              message.identifier,
              error?.toString(),
              stack?.toString(),
            ));
          });

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

class _IsoxErrorContainer {
  final int identifier;
  final String message;
  final String stackTrace;

  _IsoxErrorContainer(
    this.identifier,
    this.message,
    this.stackTrace,
  );
}
