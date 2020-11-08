import 'dart:isolate';

import 'package:isox/src/isox_command.dart';

class IsoxInstance<S> {
  final Isolate _isolate;

  final SendPort _mtiPort;
  final ReceivePort _itmPort;

  IsoxInstance(this._isolate, this._mtiPort, this._itmPort);

  Future<O> run<I, O>(IsoxCommand<I, O, dynamic> command, I input) {}
}
