import 'package:test/test.dart';
import 'package:wb_annatation/wb_annatation.dart';

void main() {
  group('WbMqttTopics.toBrokerTopic', () {
    test('meta устройства', () {
      expect(
        WbMqttTopics.toBrokerTopic('room_light/meta'),
        '/devices/room_light/meta',
      );
    });

    test('meta контрола', () {
      expect(
        WbMqttTopics.toBrokerTopic('room_light/lamp/meta'),
        '/devices/room_light/controls/lamp/meta',
      );
    });

    test('value топик контрола', () {
      expect(
        WbMqttTopics.toBrokerTopic('test-dev/temperature'),
        '/devices/test-dev/controls/temperature',
      );
    });

    test('on топик контрола', () {
      expect(
        WbMqttTopics.toBrokerTopic('room_light/lamp/on'),
        '/devices/room_light/controls/lamp/on',
      );
    });

    test('невалидный топик', () {
      expect(
        () => WbMqttTopics.toBrokerTopic('only_device'),
        throwsArgumentError,
      );
    });
  });

  group('WbMqttTopics.fromBrokerTopic', () {
    test('round-trip для всех форм', () {
      final topics = [
        'room_light/meta',
        'room_light/lamp/meta',
        'room_light/lamp/on',
        'test-dev/temperature',
      ];

      for (final short in topics) {
        final broker = WbMqttTopics.toBrokerTopic(short);
        expect(WbMqttTopics.fromBrokerTopic(broker), short);
      }
    });

    test('неизвестный broker топик', () {
      expect(WbMqttTopics.fromBrokerTopic('/other/topic'), isNull);
      expect(
        WbMqttTopics.fromBrokerTopic('/devices/room_light/controls/lamp/extra'),
        isNull,
      );
    });
  });
}
