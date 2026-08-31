import 'dart:convert';

/// Типы контролов Wiren Board MQTT.
///
/// См. https://github.com/wirenboard/conventions#3-control-types
enum WbControlType {
  switch_('switch'),
  woSwitch('wo-switch'),
  alarm('alarm'),
  pushbutton('pushbutton'),
  range('range'),
  rgb('rgb'),
  text('text'),
  unixtime('unixtime'),
  w1Id('w1-id'),
  value('value');

  const WbControlType(this.mqttValue);

  /// Значение для поля `type` в JSON метаданных контрола.
  final String mqttValue;

  /// Сериализует meta контрола в JSON-строку для MQTT.
  static String meta(Map<String, dynamic> fields) => jsonEncode(fields);

  static WbControlType fromString(String str) {
    for (final t in values) {
      if (t.mqttValue == str) return t;
    }

    throw FormatException('Unknown control type: $str');
  }

  /// Все допустимые значения `type` из conventions.
  static const mqttValues = [
    'switch',
    'wo-switch',
    'alarm',
    'pushbutton',
    'range',
    'rgb',
    'text',
    'unixtime',
    'w1-id',
    'value',
  ];
}
