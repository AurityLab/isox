import 'package:isox/isox.dart';

typedef IsoxCommandRunner<I, O, S> = Future<O> Function(I, S);

/// Defines a command within Isox. A command can have an input (of type [I]),
/// output (of type [O]) and a state (of type [S]).
///
/// The [name] of a command has to be unique within an [IsoxConfig].
///
class IsoxCommand<I, O, S> {
  final String _name;
  final IsoxCommandRunner<I, O, S> _runner;
  final bool hasResponseOverride;

  const IsoxCommand(
    this._name,
    this._runner, {
    this.hasResponseOverride,
  });

  /// Will return the unique name of this command. (This has to be at least
  /// unique within the consumer). This must not return null!
  String get name => _name;

  /// Defines if this command has to return a response to the parent. If this
  /// is false, the returned future of the parent will resolve immediately with
  /// an empty future.
  /// By default this will return true of the output type is not 'void'.
  /// This behavior can be overridden using th [hasResponseOverride] parameter
  /// from the constructor.
  bool get hasResponse => hasResponseOverride ?? O.toString() != 'void';

  /// Will run the action behind this command.
  Future<O> run(I input, S state) => _runner(input, state);
}

/// Implementation of a [IsoxCommand] which is accepts a [IsoxCommandRunner]
/// in the constructor. The [_runner] must be a top-level function to work!
///
/// ```dart
/// const addCommand = InlineIsoxCommand('add', _exec)
/// Future<int> _exec(int input, int state) async => state = (state + input);
/// ```
/*class InlineIsoxCommand<I, O, S> extends IsoxCommand<I, O, S> {
  final String _name;
  final IsoxCommandRunner<I, O, S> _runner;

  const InlineIsoxCommand(this._name, this._runner);

  @override
  Future<O> run(I input, S state) {
    return _runner(input, state);
  }

  @override
  String get name => _name;
}*/
