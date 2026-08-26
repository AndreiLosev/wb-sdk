import '../types/wb_control_type.dart';
import '../types/wb_localized_title.dart';

/// Общие метаданные контрола виртуального устройства Wiren Board MQTT.
///
/// См. https://github.com/wirenboard/conventions#22-controlss-meta-topic
class ControlAnnotation {
  const ControlAnnotation({
    required this.type,
    this.name,
    this.title,
    this.units,
    this.min,
    this.max,
    this.precision,
    this.readonly = false,
    this.hidden = false,
    this.enumTitles,
  });

  /// Тип контрола (`meta.type`).
  final WbControlType type;

  /// Имя контрола в MQTT-топике. По умолчанию — имя поля в snake_case.
  final String? name;

  /// Локализованный заголовок контрола (`meta.title`).
  ///
  /// Если не задан или [en] не задан, генератор подставит `snake_case` имени поля.
  final WbLocalizedTitle? title;

  /// Единицы измерения (`meta.units`). Только для [WbControlType.value].
  final String? units;

  /// Минимальное значение (`meta.min`).
  final double? min;

  /// Максимальное значение (`meta.max`).
  final double? max;

  /// Точность значения (`meta.precision`).
  final double? precision;

  /// Контрол только для чтения, без `/on` топика (`meta.readonly`).
  final bool readonly;

  /// Скрытый контрол, не отображается в UI (`meta.hidden`).
  final bool hidden;

  /// Заголовки значений enum (`meta.enum`). Для [WbControlType.value] и [WbControlType.text].
  final Map<String, WbLocalizedTitle>? enumTitles;
}
