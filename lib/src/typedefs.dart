import 'package:isox/isox.dart';

/// Function which supplies a [consumer] and expects the initial state of
/// type [S] to be returned.
typedef IsoxIsolateInit<S> = S Function(IsoxConfig consumer);

/// Function which defines a error handler for all errors within an isolate.
typedef IsoxErrorHandler = void Function(dynamic error, StackTrace stackTrace);
