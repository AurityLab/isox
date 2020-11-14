import 'package:isox/isox.dart';
import 'package:isox/src/command.dart';
import 'package:isox/src/config.dart';

void main() async {
  // Start and wait until the Isox instance is ready to be used.
  final instance = await Isox.start(_initIsolate);

  // Run several add commands to increment the count.
  // Will increment to total of 10.
  await instance.run(addCommand, 10);
  // Will increment to total of 20.
  await instance.run(addCommand, 10);
  // Will increment to total of 30.
  final res = await instance.run(addCommand, 10);

  print(res); // Will print '30'.

  // Close the Isox instance (and kill the actual isolate)
  await instance.close();
}

/// Will initialize the Isox instance with the state and the commands.
CounterState _initIsolate(IsoxConfig config) {
  // Add an error handler to keep track of the errors within this isolate.
  config.errorHandler = (error, trace) {
    print(error);
    print(trace);
  };

  // Add the add command to the registry.
  config.command(addCommand);

  // Create the state of the instance.
  return CounterState();
}

/// Defines the state of the counter.
class CounterState {
  int count = 0;
}

/// Defines the add command and the runner below.
const addCommand = IsoxCommand('name', _exec);

Future<int> _exec(int input, CounterState state) async =>
    state.count = (state.count + input);
