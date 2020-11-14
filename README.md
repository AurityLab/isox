# Isox

Isolate runner which provides a request/response pattern for isolates.

## Usage

### Full example

```dart
import 'package:isox/isox.dart';

void main() async {
  // Start the Isox instance with the isolate.
  final instance = await Isox.start(_init);

  // Run the add command with 10 as input.
  await instance.run(addCommand, 10);

  // Close the Isox instance and the corresponding isolate.
  instance.close();
}

int _init(IsoxConfig config) {
  // Add the add command to the config.
  config.command(addCommand);

  // Return the initial state on this function.
  return 0;
}

// Define an add command with the top-level runner function.
// The name ("add" in this case) must be unique!
const addCommand = IsoxCommand('add', _exec);

Future<int> _exec(int input, int state) async => state = (state + input);
```

### Initialization

First you need to define the initializer top-level function:

```dart
int _init(IsoxConfig config) {
  /// ...
}
```

This function returns the initial state within the Isolate. Through the config you can define various things which are
necessary to interact with the Isolate later.
**Note:** This function MUST be top-level, otherwise it will fail to initialize.

Now you need to start the actual Isox instance:

```dart
void main() async {
  final isox = await Isox.start(_init);
}
```

This requires the previously defined initializer function. This will return the actual IsoxInstance as a future.

### Commands

As this library provides an abstraction for the bidirectional communication between the main process, and the isolate,
you need to define your commands within the Isolate. A command can accept a single input parameter and return a single
value back to the main process.

The easiest way to define a command is like this:

```dart

const addCommand = IsoxCommand('add', _exec);

/// The actual function which will be executed on call. 
/// This provides the input parameter and the current state.
Future<int> _exec(int input, int state) async => state = (state + input);
```

**Note:** The name of the command ("add" in this case) MUST be unique!

If you have a command which returns `void`, the main process won't wait for completion of the command runner. You can
override this behavior by passing the `hasResponseOverride` parameter to the IsoxCommand constructor:

```dart

const addCommand = IsoxCommand('add', _exec, hasResponseOverride: true);
```

### Registering commands

The Isolate process needs to be configured to accept a command. This can be done in the initializer function from
the [Initialization](#initialization) section.

Here's an example:

```dart
int _init(IsoxConfig config) {
  // Add the previously defined add command to the config.
  config.command(addCommand);

  // ...
}
```

**Note:** An exception will be thrown if you try to register to command twice or register a command with the same name!

### Executing commands

Assume we've already initialized an IsoxInstance and the `addCommand` is registered from the previous section. Through
the `IsoxInstance` you can run any registered command on the Isolate process.

Example:

```dart
void main() async {
  // ...

  // Will run the addCommand with '10' as input.
  final response = await instance.run(addCommand, 10);
}
```

The output will be returned as a future from the `run` method.

### State

As you can keep the Isox instance alive, you may need to persist various values through multiple command calls.

You can provide an initial state through the initializer function like this:

```dart
int _init(IsoxConfig config) {
  // Provide 0 as initial state.
  return 0;
}
```

The state can be access on each command like this:

```dart

const addCommand = IsoxCommand('add', _exec);

Future<int> _exec(int input, int state) async {
  // Second parameter provides the state.
  // ... 
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/AurityLab/isox/issues
