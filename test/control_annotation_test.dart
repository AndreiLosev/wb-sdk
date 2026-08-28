import 'package:test/test.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  group('WbControlType', () {
    test('содержит все 10 типов из conventions', () {
      expect(WbControlType.values, hasLength(10));
      expect(WbControlType.mqttValues, hasLength(10));
    });

    test('mqttValue совпадает со строками Wiren Board', () {
      expect(WbControlType.switch_.mqttValue, 'switch');
      expect(WbControlType.woSwitch.mqttValue, 'wo-switch');
      expect(WbControlType.alarm.mqttValue, 'alarm');
      expect(WbControlType.pushbutton.mqttValue, 'pushbutton');
      expect(WbControlType.range.mqttValue, 'range');
      expect(WbControlType.rgb.mqttValue, 'rgb');
      expect(WbControlType.text.mqttValue, 'text');
      expect(WbControlType.unixtime.mqttValue, 'unixtime');
      expect(WbControlType.w1Id.mqttValue, 'w1-id');
      expect(WbControlType.value.mqttValue, 'value');
    });

    test('все enum-значения перечислены в mqttValues', () {
      final fromEnum = WbControlType.values.map((t) => t.mqttValue).toList();
      expect(fromEnum, containsAll(WbControlType.mqttValues));
      expect(WbControlType.mqttValues, containsAll(fromEnum));
    });
  });

  group('WbLocalizedTitle', () {
    test('создаётся с en и опциональным ru', () {
      const title = WbLocalizedTitle(en: 'Room Light', ru: 'Освещение');
      expect(title.en, 'Room Light');
      expect(title.ru, 'Освещение');
    });

    test('ru может быть null', () {
      const title = WbLocalizedTitle(en: 'Room Light');
      expect(title.ru, isNull);
    });
  });

  group('WbMetaJson', () {
    test('собирает meta устройства', () {
      const title = WbLocalizedTitle(en: 'Room Light', ru: 'Освещение');
      expect(
        WbMetaJson.device(title),
        '{"driver":"vktmotage","title":{"en":"Room Light","ru":"Освещение"}}',
      );
    });

    test('пустой title при null', () {
      expect(
        WbMetaJson.device(null),
        '{"driver":"vktmotage","title":{}}',
      );
    });
  });

  group('аннотации', () {
    test('VirtualDevice, InputControl и OutputControl const-конструируемы', () {
      const device = VirtualDevice();

      const inputControl = InputControl(
        type: WbControlType.switch_,
        name: 'switch',
        title: WbLocalizedTitle(en: 'Switch', ru: 'Выключатель'),
      );

      const outputControl = OutputControl(
        type: WbControlType.switch_,
        name: 'lamp',
        title: WbLocalizedTitle(en: 'Lamp', ru: 'Лампа'),
      );

      const valueInput = InputControl(
        type: WbControlType.value,
        units: WbUnits.watt,
        min: 0,
        max: 5000,
        precision: 0.1,
        readonly: true,
        hidden: false,
        title: WbLocalizedTitle(en: 'Power', ru: 'Мощность'),
      );

      const enumOutput = OutputControl(
        type: WbControlType.text,
        enumTitles: {
          '0': WbLocalizedTitle(en: 'Off', ru: 'Выкл'),
          '1': WbLocalizedTitle(en: 'On', ru: 'Вкл'),
        },
        title: WbLocalizedTitle(en: 'Mode', ru: 'Режим'),
      );

      expect(device, isA<VirtualDevice>());

      expect(inputControl, isA<ControlAnnotation>());
      expect(inputControl.type, WbControlType.switch_);
      expect(inputControl.name, 'switch');

      expect(outputControl, isA<ControlAnnotation>());
      expect(outputControl.type, WbControlType.switch_);
      expect(outputControl.name, 'lamp');

      expect(valueInput.units, WbUnits.watt);
      expect(valueInput.min, 0);
      expect(valueInput.max, 5000);
      expect(valueInput.precision, 0.1);
      expect(valueInput.readonly, isTrue);

      expect(enumOutput.enumTitles, isNotNull);
      expect(enumOutput.enumTitles!['0']!.ru, 'Выкл');
    });

    test('пример класса с аннотациями компилируется', () {
      final roomLight = _RoomLight(_FakeWbMqttClient());
      expect(roomLight.switchState, isFalse);
      expect(roomLight.lamp, isFalse);
      expect(roomLight.power, 0);
      expect(roomLight.mode, '0');
    });
  });
}

class _FakeWbMqttClient implements WbMqttClient {
  @override
  Stream<WbMqttMessage> get messages => const Stream.empty();

  @override
  void publish(String topic, String payload, {bool retained = false}) {}

  @override
  void subscribe(String topic) {}

  @override
  void unsubscribe(String topic) {}
}

@VirtualDevice()
class _RoomLight implements IDevice {
  _RoomLight(this.mqtt);

  @override
  final WbMqttClient mqtt;

  @override
  final String name = 'room_light';

  @override
  final WbLocalizedTitle? title = WbLocalizedTitle(
    en: 'Room Light',
    ru: 'Освещение комнаты',
  );

  @InputControl(
    type: WbControlType.switch_,
    title: WbLocalizedTitle(en: 'Switch', ru: 'Выключатель'),
  )
  final bool switchState = false;

  @OutputControl(
    type: WbControlType.switch_,
    title: WbLocalizedTitle(en: 'Lamp', ru: 'Лампа'),
  )
  final bool lamp = false;

  @InputControl(
    type: WbControlType.value,
    units: WbUnits.watt,
    min: 0,
    max: 5000,
    precision: 0.1,
    readonly: true,
    title: WbLocalizedTitle(en: 'Power', ru: 'Мощность'),
  )
  final double power = 0;

  @OutputControl(
    type: WbControlType.text,
    enumTitles: {
      '0': WbLocalizedTitle(en: 'Off', ru: 'Выкл'),
      '1': WbLocalizedTitle(en: 'On', ru: 'Вкл'),
    },
    title: WbLocalizedTitle(en: 'Mode', ru: 'Режим'),
  )
  final String mode = '0';

  @override
  void execute() {}

  @override
  void init() {}

  @override
  Set<String> inputs() => const {};

  @override
  Set<String> outputs() => const {};

  @override
  void updateField(WbMqttMessage mess) {}
}
