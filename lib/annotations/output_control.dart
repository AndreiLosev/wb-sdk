import 'package:meta/meta_meta.dart';

import 'control_annotation.dart';

/// Выходной контрол: поле публикует значение в MQTT.
///
/// Генератор подписывается на `{name}/{control}/on`,
/// публикует значение в `{name}/{control}` через `set{Field}`.
@Target({TargetKind.field})
class OutputControl extends ControlAnnotation {
  const OutputControl({
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
