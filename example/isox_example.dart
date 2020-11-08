import 'package:isox/src/isox_command.dart';
import 'package:isox/src/isox_command_registry.dart';
import 'package:isox/src/isox_consumer.dart';
import 'package:isox/src/isox_facade.dart';

void main() async {
  final instance = Isox.start(_initIsolate);

  final result = await instance.run(addCommand, 1);

  // final result = await instance.run(addCommand, 10);
  // print(result);
}

const addCommand = InlineIsoxCommand('name', _exec);
Future<int> _exec(int input, CounterState state) async {
  return ++state.count;
}

CounterState _initIsolate(IsoxRegistry<CounterState> consumer) {
  consumer.add(addCommand);

  return CounterState();
}

class CounterState {
  int count;
}

/*
const addCommand = InlineIsoxCommand('name', _exec);
Future<int> _exec(int input, CounterState state) async {
  return ++state.count;
}

const addCommand = InlineIsoxCommand('add', _exec);

Future<int> _exec(int input, CounterState state) async {
  return ++state.count;
}

const add2Command = InlineIsoxCommand('add2', _exec2);

Future<int> _exec2(int input, CounterState state) async {
  state.count = state.count + 2;
  return state.count;
}

class SubtractCommand extends IsoxCommand<int, int, CounterState> {
  const SubtractCommand();

  @override
  Future<int> run(int input, CounterState state) async {
    return --state.count;
  }

  @override
  String get name => 'subtract';
}*/
