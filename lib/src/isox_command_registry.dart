import 'package:isox/src/isox_command.dart';

class IsoxRegistry<S> {
  final List<IsoxCommand<dynamic, dynamic, S>> _commands = [];

  void add (IsoxCommand<dynamic, dynamic, S> command) {
    _commands.add(command);
  }
}
