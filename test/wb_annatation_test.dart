import 'package:test/test.dart';
import 'package:wb_annatation/wb_annatation.dart';

void main() {
  test('публичный API экспортирует аннотации и типы', () {
    expect(VirtualDevice, isNotNull);
    expect(ControlAnnotation, isNotNull);
    expect(InputControl, isNotNull);
    expect(OutputControl, isNotNull);
    expect(WbControlType, isNotNull);
    expect(WbLocalizedTitle, isNotNull);
    expect(WbUnits, isNotNull);
    expect(WbValueCodec, isNotNull);
    expect(WbMetaJson, isNotNull);
    expect(WbNumericBounds, isNotNull);
    expect(WbMqttClient, isNotNull);
    expect(WbStorage, isNotNull);
    expect(WbHiveStorage, isNotNull);
    expect(IDevice, isNotNull);
  });
}
