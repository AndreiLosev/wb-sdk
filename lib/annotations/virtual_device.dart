import 'package:meta/meta_meta.dart';

import '../types/wb_localized_title.dart';

/// Аннотация виртуального устройства Wiren Board MQTT.
///
/// См. https://github.com/wirenboard/conventions#1-basic-concepts
@Target({TargetKind.classType})
class VirtualDevice {
  const VirtualDevice({required this.name, required this.title});

  /// Имя устройства в коротком MQTT-топике (`{name}/...`).
  final String name;

  /// Локализованный заголовок устройства (`meta.title`).
  final WbLocalizedTitle title;
}
