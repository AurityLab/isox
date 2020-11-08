import 'package:isox/src/isox_command.dart';
import 'package:isox/src/isox_consumer.dart';
import 'package:isox/src/isox_instance.dart';
import 'package:isox/src/isox_loader.dart';

class Isox {
  static IsoxInstance start<S>(IsoxIsolateInit<S> init) {}
  static IsoxInstance startStatless<S>(IsoxIsolateInit<S> init) {}
}
