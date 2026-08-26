import 'package:meta/meta_meta.dart';

import 'control_annotation.dart';

/// Входной контрол: поле получает значение из MQTT.
///
/// Генератор подписывается на `{name}/{control}/on`.
@Target({TargetKind.field})
class InputControl extends ControlAnnotation {
  const InputControl({
    required super.type,
    super.name,
    super.title,
    super.units,
    super.min,
    super.max,
    super.precision,
    super.readonly = false,
    super.hidden = false,
    super.enumTitles,
  });
}
