import 'package:test/test.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  group('WbValueCodec', () {
    test('кодирует bool как 0/1', () {
      expect(WbValueCodec.encodeBool(true), '1');
      expect(WbValueCodec.encodeBool(false), '0');
    });

    test('encode/decode для типов контролов', () {
      expect(
        WbValueCodec.encode(true, WbControlType.switch_),
        '1',
      );
      expect(
        WbValueCodec.decode('0', WbControlType.switch_),
        isFalse,
      );
      expect(
        WbValueCodec.encode(42, WbControlType.range),
        '42',
      );
      expect(
        WbValueCodec.encode(3.14, WbControlType.value),
        '3.14',
      );
      expect(
        WbValueCodec.encode('auto', WbControlType.text),
        'auto',
      );
    });

    test('encode/decode для WbControlType.value с int и double', () {
      expect(
        WbValueCodec.encode(42, WbControlType.value),
        '42',
      );
      expect(
        WbValueCodec.encode(3.14, WbControlType.value),
        '3.14',
      );
      expect(WbValueCodec.decodeIntValue('42'), 42);
      expect(WbValueCodec.decodeDoubleValue('42'), 42.0);
      expect(WbValueCodec.decodeDoubleValue('3.14'), 3.14);
      expect(
        WbValueCodec.decode('42', WbControlType.value),
        42,
      );
      expect(
        WbValueCodec.decode('3.14', WbControlType.value),
        3.14,
      );
    });
  });
}
