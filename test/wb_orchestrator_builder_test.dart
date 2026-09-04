import 'package:test/test.dart';
import 'package:wb_sdk/wb_sdk.dart';

import 'support/fakes.dart';

void main() {
  tearDown(WbMqttTopics.clearExternalPrefixes);

  group('WbOrchestratorBuilder', () {
    late FakeWbMqttClient mqtt;
    late FakeDevice deviceA;
    late FakeExternalService weatherService;

    setUp(() {
      mqtt = FakeWbMqttClient();
      deviceA = FakeDevice(
        name: 'dev_a',
        inputs: {'temp/on'},
      );
      weatherService = FakeExternalService(prefix: 'weather/');
    });

    WbOrchestratorBuilder createBuilder() {
      return WbOrchestratorBuilder(
        mqttHost: 'localhost',
        mqttClientId: 'test-client',
        storageDirectory: '/tmp/wb-test',
        mqttClientFactory: () async => mqtt,
        storageFactory: () async => FakeStorage(),
      );
    }

    test('build с services возвращает оркестратор', () async {
      final orchestrator = await createBuilder().build(
        devices: [deviceA],
        services: [weatherService],
      );

      expect(orchestrator, isA<WbOrchestrator>());
    });

    test('build с services подписывается на prefix# при prepare', () async {
      weatherService.deps.add('sensor/outside/temp/on');
      final orchestrator = await createBuilder().build(
        devices: [deviceA],
        services: [weatherService],
      );

      orchestrator.prepare();

      expect(mqtt.subscribedTopics, containsAll([
        'weather/#',
        'sensor/outside/temp/on',
      ]));
    });

    test('build с services маршрутизирует сообщения во внешний сервис', () async {
      final orchestrator = await createBuilder().build(
        devices: [deviceA],
        services: [weatherService],
      );

      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'weather/sensor/temp/on', payload: '22.0'),
      );

      expect(weatherService.messages, hasLength(1));
      expect(weatherService.messages.first.topic, 'sensor/temp/on');
      expect(weatherService.messages.first.payload, '22.0');
      expect(deviceA.updateFieldCalls, 0);
    });
  });
}
