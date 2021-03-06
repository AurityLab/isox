import 'package:isox/isox.dart';

/// Defines a command within Isox. A command can have an input (of type [I]),
/// output (of type [O]) and a state (of type [S]).
///
/// The [name] of a command has to be unique within an [IsoxConfig].
class IsoxCommand<I, O, S> {
  final String _name;
  final IsoxCommandRunner<I, O, S> _runner;
  final bool wait;

  const IsoxCommand(
    this._name,
    this._runner, {
    this.wait = true,
  });

  /// Will return the unique name of this command. (This has to be at least
  /// unique within the consumer). This must not return null!
  String get name => _name;

  /// Defines if this command has to return a response to the parent. If this
  /// is false, the returned future of the parent will resolve immediately with
  /// an empty future.
  /// By default, this is true. See [wait] parameter.
  bool get waitForResponse => wait;

  /// Will run the action behind this command.
  Future<O> run(I input, S state) => _runner(input, state);
}
