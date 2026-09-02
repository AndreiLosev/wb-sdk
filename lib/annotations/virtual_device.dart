import 'package:meta/meta_meta.dart';

/// Аннотация виртуального устройства Wiren Board MQTT.
///
/// См. https://github.com/wirenboard/conventions#1-basic-concepts
@Target({TargetKind.classType})
class VirtualDevice {
  const VirtualDevice({this.dependencies = const []});

  /// Внешние MQTT-топики, на которые подписывается устройство.
  ///
  /// При сообщении оркестратор вызывает [IDevice.execute].
  final List<String> dependencies;
}
