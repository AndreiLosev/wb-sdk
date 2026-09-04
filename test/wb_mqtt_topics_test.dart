import 'package:test/test.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  tearDown(WbMqttTopics.clearExternalPrefixes);

  group('WbMqttTopics external prefixes', () {
    setUp(() {
      WbMqttTopics.registerExternalPrefixes(['weather/']);
    });

    test('toBrokerTopic passthrough для внешнего prefix', () {
      expect(
        WbMqttTopics.toBrokerTopic('weather/sensor/temp/on'),
        '/weather/sensor/temp/on',
      );
      expect(
        WbMqttTopics.toBrokerTopic('weather/#'),
        '/weather/#',
      );
    });

    test('fromBrokerTopic round-trip для внешнего prefix', () {
      const short = 'weather/sensor/temp/on';
      final broker = WbMqttTopics.toBrokerTopic(short);
      expect(WbMqttTopics.fromBrokerTopic(broker), short);
    });
  });

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

    test('io_mapping input-топик', () {
      expect(
        WbMqttTopics.toBrokerTopic('io_mapping/inputs/alias/temp/on'),
        '/io_mapping/inputs/alias/temp/on',
      );
    });

    test('io_mapping wildcard', () {
      expect(
        WbMqttTopics.toBrokerTopic('io_mapping/inputs/#'),
        '/io_mapping/inputs/#',
      );
    });

    test('debug flag-топик', () {
      expect(
        WbMqttTopics.toBrokerTopic('debug/room_light'),
        '/debug/room_light',
      );
    });

    test('debug message-топик', () {
      expect(
        WbMqttTopics.toBrokerTopic(
          'debug/room_light/2024-08-28T17:39:00.123',
        ),
        '/debug/room_light/2024-08-28T17:39:00.123',
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
        'io_mapping/inputs/alias/temp/on',
        'io_mapping/outputs/dev_a/lamp/on',
        'io_mapping/inputs/#',
        'debug/room_light',
        'debug/room_light/2024-08-28T17:39:00.123',
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
