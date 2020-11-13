import 'package:isox/src/isox_command.dart';
import 'package:isox/src/isox_command_registry.dart';
import 'package:isox/src/isox_facade.dart';

void main() async {
  // Star the Isolate
  final instance = await Isox.start(_initIsolate);
  print(instance);

  await instance.run(addCommand, 10);
  await instance.run(addCommand, 10);
  final addResult = await instance.run(addCommand, 10);
  print(addResult);

  await instance.close();
}

class CounterState {
  int count = 0;
}

CounterState _initIsolate(IsoxRegistry registry) {
  registry.errorHandler = (error, trace) {
    print(error);
    print(trace);
  };

  registry.add(addCommand);
  registry.add(addCommand);

  return CounterState();
}

const addCommand = InlineIsoxCommand('name', _exec);

Future<int> _exec(int input, CounterState state) async =>
    state.count = (state.count + input);
