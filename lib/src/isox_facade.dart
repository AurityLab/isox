import 'package:isox/src/isox_instance.dart';

class Isox {
  /// Will start a new stateful [IsoxInstance] using the given [init] function.
  static Future<IsoxInstance> start<S>(
    IsoxIsolateInit<S> init, {
    bool keepAlive = true,
  }) {
    return IsoxInstance.loadIsolate<S>(init);
  }
}
