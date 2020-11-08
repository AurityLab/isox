import 'package:isox/src/isox_command.dart';

/// Describes the consumer within the isolate which handles the calls from
/// the producer and the actual execution.
abstract class IsoXConsumer<S> {
  final List<IsoxCommand> _commands = [];

  void addCommand (IsoxCommand<dynamic, dynamic, S> command)  {
    _commands.add(command);
  }
}
