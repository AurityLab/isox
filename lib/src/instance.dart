import 'dart:async';
import 'dart:isolate';

import 'package:isox/isox.dart';
import 'package:isox/src/config_implementation.dart';
import 'package:isox/src/exceptions.dart';
import 'package:isox/src/group.dart';

/// An instance which basically represents a single running Isolate. Commands
/// can be executing on the Isolate using [run]. To shutdown the Isolate,
/// [close] must be called.
class IsoxInstance<S> {
  // The isolate which is represented by this instance.
  final IsoxGroup _group;

  // The ports to the Isolate.
  final SendPort _mtiPort;
  final ReceivePort _itmPort;

  // The itm subscription.
  final StreamSubscription<dynamic> _subscription;

  // Counter for the commands sent to the isolate.
  int _count = 0;

  final Map<int, Completer<dynamic>> _commandCompleter = {};

  IsoxInstance._(
    this._group,
    this._mtiPort,
    this._itmPort,
    this._subscription,
  ) {
    _bindListener();
  }

  /// Will load an [IsoxInstance] with the given [init] function.
  /// The [init] function must be a top-level function, otherwise the
  /// instantiation will fail.
  /// If [group] is null, a new (private) one will be created just for this
  /// instance.
  ///
  /// See [Isox.start] for usage with the facade.
  static Future<IsoxInstance<S>> loadIsolate<S>(
    IsoxInit<S> init, {
    IsoxGroup group,
  }) async {
    // Define the completer for the initialization of this instance.
    // The future of this completer will later on be returned by this method.
    final completer = Completer<IsoxInstance<S>>();

    // Create a receive port for isolate to main communication.
    final itm = ReceivePort();

    // Start a new group if none is given.
    group ??= await Isox.startGroup();
    final internalGroup = group as InternalIsoxGroup;

    // Holds the subscription for the isolate-to-main port.
    StreamSubscription itmSubscription;

    // Add a listener to the isolate-to-main port.
    itmSubscription = itm.listen((message) {
      if (message is SendPort) {
        // Create the instance and send it to the completer.
        completer.complete(
          IsoxInstance._(
            group,
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

    // Start the actual isolate in paused state to initialize all listeners
    // for the ports.
    await internalGroup.attachInstance(
      _loadIsoxIsolate,
      IsoxIsolateInitializer<S>(init, itm.sendPort),
    );

    //isolate.resume(isolate.pauseCapability);

    return completer.future;
  }

  /// Will execute the given [command] on the Isolate with the given [input].
  /// The returned [Future] will be resolved after the command runner has been
  /// completed on the Isolate or the command does not wait for a response.
  /// If the [command] is not registered, an [IsoxCommandNotFoundException]
  /// will be thrown. If an error/exception during the command execution
  /// occurs, an [IsoxWrappedException] will be thrown.
  Future<O> run<I, O>(IsoxCommand<I, O, S> command, I input) {
    final identifier = _count++;

    // Create the request object.
    final request = _IsoxInstanceRequest(
      identifier,
      command.name,
      input,
    );

    // Return immediately if no response is expected.
    if (!command.waitForResponse) {
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
    //_isolate.kill();
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
    _subscription.onData(_handleIsolateMessage);
  }

  /// Accepts incoming messages from the Isolate. This covers the basic
  /// responses from an Isolate.
  void _handleIsolateMessage(dynamic message) {
    if (message is _IsoxInstanceResponse) {
      _completeCommand(message.identifier, (completer) {
        completer.complete(message.commandOutput);
      });
    } else if (message is _IsoxErrorContainer) {
      _completeCommand(message.identifier, (completer) {
        completer.completeError(IsoxWrappedException(
          message.message,
          StackTrace.fromString(message.stackTrace),
        ));
      });
    } else if (message is _IsoxCommandNotFoundResponse) {
      _completeCommand(message.identifier, (completer) {
        completer.completeError(IsoxCommandNotFoundException(
          message.command,
        ));
      });
    }
  }

  /// Will complete the command with the given [identifier]. After executing
  /// the [callback], the completer will be removed from the waiting
  /// commands list.
  void _completeCommand(int identifier, void Function(Completer) callback) {
    final completer = _commandCompleter[identifier];

    callback(completer);

    _commandCompleter.remove(identifier);
  }
}

void _loadIsoxIsolate<S>(IsoxIsolateInitializer<S> initializer) {
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
        final cmdResult = await runZonedGuarded(() async {
          return await cmd.run(message.commandInput, state);
        }, (error, stack) {
          itm.send(_IsoxErrorContainer(
            message.identifier,
            error?.toString(),
            stack?.toString(),
          ));

          if (config.errorHandler != null) {
            config.errorHandler(error, stack);
          }
        });

        itm.send(_IsoxInstanceResponse(message.identifier, cmdResult));
      } else {
        itm.send(_IsoxCommandNotFoundResponse(
          message.identifier,
          message.commandName,
        ));
      }
    }
  });
}

class IsoxIsolateInitializer<S> {
  final IsoxInit<S> init;
  final SendPort sendPort;

  IsoxIsolateInitializer(this.init, this.sendPort);
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

class _IsoxCommandNotFoundResponse {
  final int identifier;
  final String command;

  _IsoxCommandNotFoundResponse(
    this.identifier,
    this.command,
  );
}
