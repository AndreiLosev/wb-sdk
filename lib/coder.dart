import 'types/wb_control_type.dart';

abstract final class WbValueCodec {
  static String encodeBool(bool value) => value ? '1' : '0';

  static bool decodeBool(String payload) => payload == '1';

  static String encodeInt(int value) => value.toString();

  static int decodeInt(String payload) => int.parse(payload);

  static String encodeDouble(double value) => value.toString();

  static double decodeDouble(String payload) => double.parse(payload);

  static String encodeString(String value) => value;

  static String decodeString(String payload) => payload;

  /// Кодирует значение поля в MQTT payload по [type].
  static String encode(Object? value, WbControlType type) {
    return switch (value) {
      final bool v when _isBoolType(type) => encodeBool(v),
      final int v when _isIntType(type) => encodeInt(v),
      final double v when type == WbControlType.value => encodeDouble(v),
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
      WbControlType.range ||
      WbControlType.unixtime ||
      WbControlType.w1Id => decodeInt(payload),
      WbControlType.value => decodeDouble(payload),
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
      WbControlType.range ||
      WbControlType.unixtime ||
      WbControlType.w1Id => true,
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
