import 'dart:collection';

import 'package:isox/isox.dart';

class InternalIsoxConfig implements IsoxConfig {
  /// Holds all available commands within this config. The commands are
  /// mapped by their corresponding keys.
  final Map<String, IsoxCommand<dynamic, dynamic, dynamic>> _commandsMap =
      HashMap();

  /// Holds the [IsoxErrorHandler] instance within this config.
  IsoxErrorHandler _errorHandler;

  /// Will add the given [command] to the registry. [command] must not be null.
  /// If there is already a command with the same name,
  /// a [IsoxRegistryDuplicationException] will be thrown.
  @override
  void command(IsoxCommand<dynamic, dynamic, dynamic> command) {
    assert(command != null);

    // Check for duplicates.
    _checkDuplicate(command.name);

    // Add the given command to the list.
    _commandsMap[command.name] = command;
  }

  // void operator |(IsoxCommand<dynamic, dynamic, dynamic> command) => add(command);

  // Will return all registered commands as an immutable map.
  Map<String, IsoxCommand<dynamic, dynamic, dynamic>> get commands =>
      UnmodifiableMapView(_commandsMap);

  /// Will return the ErrorHandler from this config.
  IsoxErrorHandler get errorHandler => _errorHandler;

  @override
  set errorHandler(IsoxErrorHandler handler) => _errorHandler = handler;

  /// Will check if there is already a command registered with the given [name].
  /// If there is already one, an exception will be thrown.
  void _checkDuplicate(String name) {
    final hasDuplicate = _commandsMap.containsKey(name);

    if (hasDuplicate) {
      // Throw an exception which indicates the duplicate name.
      throw IsoxRegistryDuplicationException(name);
    }
  }
}

/// Defines an exception which will be thrown when there is already a command
/// with the same name.
class IsoxRegistryDuplicationException implements Exception {
  final String duplicatedName;

  IsoxRegistryDuplicationException(this.duplicatedName);

  @override
  String toString() {
    return "Command with name '$duplicatedName' is already registered";
  }
}
