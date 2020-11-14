import 'package:isox/isox.dart';

/// Typedef which will be used to initialize the Isox isolate. This provides
/// a [config] and expects the initial state (of type [S]) to be returned.
typedef IsoxInit<S> = S Function(IsoxConfig config);

/// Typedef which will be used to catch all errors from an isolate.
typedef IsoxErrorHandler = void Function(dynamic error, StackTrace stackTrace);

/// Typedef which will be used to execute the actual command.
typedef IsoxCommandRunner<I, O, S> = Future<O> Function(I, S);
