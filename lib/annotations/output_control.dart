import 'package:meta/meta_meta.dart';

import 'control_annotation.dart';

/// Выходной контрол: поле публикует значение в MQTT.
///
/// Генератор публикует в control-топик и обрабатывает `/on`.
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
    super.order,
    super.readonly = false,
    super.hidden = false,
    super.enumTitles,
  });
}
