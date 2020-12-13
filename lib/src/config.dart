import 'package:isox/isox.dart';
import 'package:isox/src/config_implementation.dart';

/// Describes the configuration for an Isox isolate. Using this config, the
/// commands can be registered and an error handler can be set.
///
/// An object of this class must not be modified after the Isox instance
/// initialization.
abstract class IsoxConfig {
  /// Will add the given [command] to this config. The [command] must not be
  /// null. If there is already a command with the same name, a
  ///[IsoxCommandDuplicationException] will be thrown.
  void command(IsoxCommand<dynamic, dynamic, dynamic> command);

  /// Will set the [IsoxErrorHandler] for this config.
  set errorHandler(IsoxErrorHandler handler);
}

