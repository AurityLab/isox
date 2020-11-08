typedef IsoxCommandRunner<I, O, S> = Future<O> Function(I, S);

abstract class IsoxCommand<I, O, S> {
  const IsoxCommand();

  /// Will return the unique name of this command. (This has to be at least
  /// unique within the consumer). This must not return null!
  String get name;

  /// Will run the action behind this command.
  Future<O> run(I input, S state);
}

class InlineIsoxCommand<I, O, S> extends IsoxCommand<I, O, S> {
  final String _name;
  final IsoxCommandRunner<I, O, S> _runner;

  const InlineIsoxCommand(this._name, this._runner);

  @override
  Future<O> run(I input, S state) {
    return _runner(input, state);
  }

  @override
  String get name => _name;
}
