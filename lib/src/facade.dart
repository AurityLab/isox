import 'package:isox/isox.dart';
import 'package:isox/src/group.dart';

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
  static Future<IsoxInstance> start<S>(IsoxInit<S> init, {IsoxGroup group}) =>
      IsoxInstance.loadIsolate<S>(init);

  /// Will start a new [IsoxGroup].
  static Future<IsoxGroup> startGroup() => IsoxGroup.loadGroup();
}
