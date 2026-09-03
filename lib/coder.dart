import 'types/wb_control_type.dart';

abstract final class WbValueCodec {
  static String encodeBool(bool value) => value ? '1' : '0';

  static bool decodeBool(String payload) => payload == '1';

  static String encodeInt(int value) => value.toString();

  static int decodeInt(String payload) => int.parse(payload);

  static String encodeDouble(double value) => value.toString();

  static String encodeNum(num value) => switch (value) {
    int v => encodeInt(v),
    double v => encodeDouble(v),
    _ => throw ArgumentError('Invalid num type: ${value.runtimeType}'),
  };

  static num decodeNum(String payload) => num.parse(payload);

  static int decodeIntValue(String payload) {
    final value = num.parse(payload);
    return value is int ? value : value.round();
  }

  static double decodeDoubleValue(String payload) =>
      num.parse(payload).toDouble();

  static String encodeString(String value) => value;

  static String decodeString(String payload) => payload;

  /// Кодирует значение поля в MQTT payload по [type].
  static String encode(Object? value, WbControlType type) {
    return switch (value) {
      final bool v when _isBoolType(type) => encodeBool(v),
      final int v when _isIntType(type) => encodeInt(v),
      final num v when _isNumType(type) => encodeNum(v),
      final String v when _isStringType(type) => encodeString(v),
      null => '',
      _ => throw ArgumentError(
        'Cannot encode value of type ${value.runtimeType} for $type',
      ),
    };
  }

  /// Декодирует MQTT payload в значение для поля по [type].
  static Object decode(String payload, WbControlType type) {
    return switch (type) {
      WbControlType.switch_ ||
      WbControlType.woSwitch ||
      WbControlType.alarm ||
      WbControlType.pushbutton => decodeBool(payload),
      WbControlType.unixtime || WbControlType.w1Id => decodeInt(payload),
      WbControlType.range || WbControlType.value => decodeNum(payload),
      WbControlType.rgb || WbControlType.text => decodeString(payload),
    };
  }

  static bool _isBoolType(WbControlType type) {
    return switch (type) {
      WbControlType.switch_ ||
      WbControlType.woSwitch ||
      WbControlType.alarm ||
      WbControlType.pushbutton => true,
      _ => false,
    };
  }

  static bool _isIntType(WbControlType type) {
    return switch (type) {
      WbControlType.unixtime || WbControlType.w1Id => true,
      _ => false,
    };
  }

  static bool _isNumType(WbControlType type) {
    return switch (type) {
      WbControlType.range || WbControlType.value => true,
      _ => false,
    };
  }

  static bool _isStringType(WbControlType type) {
    return switch (type) {
      WbControlType.rgb || WbControlType.text => true,
      _ => false,
    };
  }
}
