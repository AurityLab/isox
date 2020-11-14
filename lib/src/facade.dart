import 'package:isox/isox.dart';

/// Facade for Isox to start a new [IsoxInstance].
///
/// Usage example:
/// ```dart
/// Isox.start(_init)
///
/// int _init(IsoxRegistry registry) {
///   // Register your commands...
///   return 0;
/// }
/// ```
class Isox {
  const Isox._();

  /// Will start a new [IsoxInstance] with the given [init] function.
  /// The [init] function must be a top-level function, otherwise the
  /// instantiation will fail.
  static Future<IsoxInstance> start<S>(IsoxIsolateInit<S> init) =>
      IsoxInstance.loadIsolate<S>(init);
}
