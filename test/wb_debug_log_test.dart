import 'package:test/test.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/debug/wb_debug_log.dart';

void main() {
  group('WbDebugLog', () {
    late _FakeWbMqttClient mqtt;
    late WbDebugLog debugLog;

    setUp(() {
      mqtt = _FakeWbMqttClient();
      debugLog = WbDebugLog(mqtt: mqtt);
    });

    test('flagTopic и messageTopic', () {
      final time = DateTime.utc(2024, 8, 28, 17, 39, 0, 123);

      expect(WbDebugLog.flagTopic('dev_a'), 'debug/dev_a');
      expect(
        WbDebugLog.messageTopic('dev_a', time),
        'debug/dev_a/2024-08-28T17:39:00.123Z',
      );
    });

    test('subscriptionTopics', () {
      expect(
        WbDebugLog.subscriptionTopics({'dev_a', 'dev_b'}),
        {'debug/dev_a', 'debug/dev_b'},
      );
    });

    test('log не публикует без включённого флага', () {
      debugLog.log('dev_a', 'msg');

      expect(mqtt.publishedTopics, isEmpty);
    });

    test('log не публикует при флаге 0 или false', () {
      debugLog.updateFlag('dev_a', '0');
      debugLog.log('dev_a', 'msg');
      debugLog.updateFlag('dev_a', 'false');
      debugLog.log('dev_a', 'msg');

      expect(mqtt.publishedTopics, isEmpty);
    });

    test('log публикует при флаге 1', () {
      debugLog.updateFlag('dev_a', '1');
      debugLog.log('dev_a', 'temperature exceeded');

      expect(mqtt.publishedTopics.length, 1);
      expect(mqtt.publishedTopics.first, startsWith('debug/dev_a/'));
      expect(mqtt.publishedPayloads, ['temperature exceeded']);
      expect(mqtt.publishedRetained, [false]);
    });

    test('log публикует при флаге true', () {
      debugLog.updateFlag('dev_a', 'TRUE');
      debugLog.log('dev_a', 'msg');

      expect(mqtt.publishedTopics.length, 1);
      expect(mqtt.publishedPayloads, ['msg']);
    });

    test('updateFlag выключает логирование', () {
      debugLog.updateFlag('dev_a', '1');
      debugLog.log('dev_a', 'first');
      debugLog.updateFlag('dev_a', '0');
      debugLog.log('dev_a', 'second');

      expect(mqtt.publishedTopics.length, 1);
      expect(mqtt.publishedPayloads, ['first']);
    });
  });
}

class _FakeWbMqttClient implements WbMqttClient {
  final publishedTopics = <String>[];
  final publishedPayloads = <String>[];
  final publishedRetained = <bool>[];

  @override
  Stream<WbMqttMessage> get messages => const Stream.empty();

  @override
  void publish(String topic, String payload, {bool retained = false}) {
    publishedTopics.add(topic);
    publishedPayloads.add(payload);
    publishedRetained.add(retained);
  }

  @override
  void subscribe(String topic) {}

  @override
  void unsubscribe(String topic) {}
}
