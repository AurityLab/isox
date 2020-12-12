/// Describes the base for all exceptions which may be thrown by the Isox library.
class IsoxException implements Exception {}

/// Describes an exception which wraps an exception from an Isolate.
/// This includes the original message from the isolate and the actual
/// stacktrace on the Isolate.
/// Instances of this exception must only exist on the main-side of Isox.
class IsoxWrappedException extends IsoxException {
  final String message;
  final StackTrace isolateStackTrace;

  IsoxWrappedException(this.message, this.isolateStackTrace);

  @override
  String toString() {
    return 'IsoxWrappedException: $message';
  }
}

/// Describes an exception which will be thrown when the Isolate failed to
/// initialize. Instances of this exception mus only exist on the main-side
/// of Isox (just like the super [IsoxWrappedException]).
class IsoxInitializationException extends IsoxWrappedException {
  IsoxInitializationException(
    String message,
    StackTrace isolateStackTrace,
  ) : super(message, isolateStackTrace);

  @override
  String toString() {
    return 'IsoxInitializationException: $message';
  }
}


/// Exception which will be thrown when a isolate has been killed before
/// completing pending requests.
class IsoxInterruptionException implements IsoxException {}
