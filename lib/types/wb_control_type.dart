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
