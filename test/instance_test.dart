import 'package:isox/isox.dart';
import 'package:test/test.dart';

void main() {
  group('Isox Instance', () {
    group('start', () {
      test('should start isolate correctly with correct initializer', () async {
        final instance = await Isox.start(_initializerTestValid);

        expect(instance, isNotNull);

        await instance.close();
      });

      test('should throw exception on invalid initializer', () {
        expect(
          () async => await Isox.start(_initializerTestInvalid),
          throwsA(TypeMatcher<IsoxInitializationException>()),
        );
      });
    });

    group('commands', () {
      IsoxInstance instance;

      setUp(() async {
        instance = await Isox.start(_initializerVoidVariety);
      });

      void _assertCalled() async {
        final counter = await instance.run(_stateCommand, null);
        expect(counter, greaterThan(0));
      }

      void _assertNotCalled() async {
        final counter = await instance.run(_stateCommand, null);
        expect(counter, equals(0));
      }

      test('should correctly execute void command', () async {
        await instance.run(_voidCommand, null);

        await _assertCalled();
      });

      test('should correctly execute overridden void command', () async {
        await instance.run(_immediateVoidCommand, null);

        await _assertNotCalled();
      });

      test('should throw exception on command runner exception', () async {
        await expect(
          () async => instance.run(_errorCommand, null),
          throwsA(TypeMatcher<IsoxWrappedException>()),
        );
      });

      test('should throw exception on sync command runner', () async {
        await expect(
          () async => instance.run(_errorSyncCommand, null),
          throwsA(TypeMatcher<IsoxWrappedException>()),
        );
      });

      test('should throw exception if command was not found', () async {
        await expect(
          () async => instance.run(_unregisteredCommand, null),
          throwsA(TypeMatcher<IsoxCommandNotFoundException>()),
        );
      });

      tearDown(() async {
        await instance.close();
        instance = null;
      });
    });
  });
}

/// A valid initializer which actually does nothing.
void _initializerTestValid(IsoxConfig config) {}

/// An invalid initializer which just throws an exception.
void _initializerTestInvalid(IsoxConfig config) {
  throw Exception('test');
}

/// An initializer which has no state but provides some commands for testing.
_SimpleState _initializerVoidVariety(IsoxConfig config) {
  config.command(_voidCommand);
  config.command(_immediateVoidCommand);
  config.command(_errorCommand);
  config.command(_errorSyncCommand);

  config.command(_stateCommand);

  return _SimpleState();
}

final _stateCommand = IsoxCommand('state', _stateCommandRunner);

Future<int> _stateCommandRunner(void input, _SimpleState state) async {
  return state.counter;
}

final _voidCommand = IsoxCommand(
  'voidCommand',
  _voidCommandRunner,
);

Future<void> _voidCommandRunner(void input, _SimpleState state) async {
  state.counter++;
}

final _immediateVoidCommand = IsoxCommand(
  'immediateVoidCommand',
  _immediateVoidCommandRunner,
  wait: false,
);

Future<void> _immediateVoidCommandRunner(void input, _SimpleState state) async {
  state.counter++;
}

final _errorCommand = IsoxCommand('errorCommand', _errorCommandRunner);

Future<void> _errorCommandRunner(void input, _SimpleState state) async {
  throw Exception('Test!');
}

final _errorSyncCommand = IsoxCommand(
  'errorSyncCommand',
  _errorSyncCommandRunner,
);

Future<void> _errorSyncCommandRunner(void input, _SimpleState state) {
  throw Exception('Test!');
}

final _unregisteredCommand = IsoxCommand(
  'unregisteredCommand',
  _unregisteredCommandRunner,
);

Future<void> _unregisteredCommandRunner(void input, _SimpleState state) {}

class _SimpleState {
  int counter = 0;
}
