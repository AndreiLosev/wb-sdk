import 'package:test/test.dart';
import 'package:wb_sdk/orchestrator/external_service_registry.dart';
import 'package:wb_sdk/orchestrator/external_service_router.dart';
import 'package:wb_sdk/wb_sdk.dart';

import 'support/fakes.dart';

void main() {
  tearDown(WbMqttTopics.clearExternalPrefixes);

  group('ExternalServiceRegistry', () {
    test('принимает валидный префикс', () {
      expect(
        () => ExternalServiceRegistry.validate(
          [FakeExternalService(prefix: 'weather/')],
          [],
        ),
        returnsNormally,
      );
      expect(WbMqttTopics.toBrokerTopic('weather/sensor/on'), '/weather/sensor/on');
    });

    test('отклоняет префикс без завершающего /', () {
      expect(
        () => ExternalServiceRegistry.validate(
          [FakeExternalService(prefix: 'weather')],
          [],
        ),
        throwsArgumentError,
      );
    });

    test('отклоняет зарезервированные префиксы', () {
      for (final prefix in ExternalServiceRegistry.reservedPrefixes) {
        expect(
          () => ExternalServiceRegistry.validate(
            [FakeExternalService(prefix: prefix)],
            [],
          ),
          throwsArgumentError,
        );
      }
    });

    test('отклоняет пересекающиеся префиксы сервисов', () {
      expect(
        () => ExternalServiceRegistry.validate(
          [
            FakeExternalService(prefix: 'weather/'),
            FakeExternalService(prefix: 'weather/station/'),
          ],
          [],
        ),
        throwsArgumentError,
      );
    });

    test('отклоняет коллизию с именем устройства', () {
      expect(
        () => ExternalServiceRegistry.validate(
          [FakeExternalService(prefix: 'dev_a/')],
          [FakeDevice(name: 'dev_a')],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ExternalServiceRouter', () {
    test('subscriptionTopics включает prefix# и dependencies', () {
      final router = ExternalServiceRouter([
        FakeExternalService(
          prefix: 'weather/',
          deps: {'sensor/outside/temp/on'},
        ),
      ]);

      expect(
        router.subscriptionTopics,
        containsAll(['weather/#', 'sensor/outside/temp/on']),
      );
    });

    test('route снимает mqttPrefix и передаёт payload без изменений', () {
      final service = FakeExternalService(prefix: 'weather/');
      final router = ExternalServiceRouter([service]);

      final routed = router.route(
        const WbMqttMessage(
          topic: 'weather/sensor/temp/on',
          payload: '21.5',
        ),
      );

      expect(routed, isTrue);
      expect(service.messages, hasLength(1));
      expect(service.messages.first.topic, 'sensor/temp/on');
      expect(service.messages.first.payload, '21.5');
    });

    test('longest-prefix match при вложенных префиксах', () {
      final outer = FakeExternalService(prefix: 'integrations/');
      final inner = FakeExternalService(prefix: 'integrations/home/');
      final router = ExternalServiceRouter([outer, inner]);

      router.route(
        const WbMqttMessage(topic: 'integrations/home/state/on', payload: '1'),
      );

      expect(outer.messages, isEmpty);
      expect(inner.messages, hasLength(1));
      expect(inner.messages.first.topic, 'state/on');
      expect(inner.messages.first.payload, '1');
    });

    test('возвращает false для чужого топика', () {
      final router = ExternalServiceRouter([
        FakeExternalService(prefix: 'weather/'),
      ]);

      expect(
        router.route(
          const WbMqttMessage(topic: 'dev_a/temp/on', payload: '1'),
        ),
        isFalse,
      );
    });
  });

  group('WbOrchestrator external services', () {
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

    test('prepare подписывается на prefix# и dependencies', () {
      weatherService.deps.add('sensor/outside/temp/on');
      final orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        devices: [deviceA],
        services: [weatherService],
      );

      orchestrator.prepare();

      expect(mqtt.subscribedTopics, containsAll([
        'weather/#',
        'sensor/outside/temp/on',
      ]));
    });

    test('handleMessage маршрутизирует во внешний сервис, не в устройство', () {
      final orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
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
      expect(deviceA.executeCalls, 0);
    });

    test('сообщения устройств по-прежнему идут в DeviceTopicRouter', () {
      final orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        devices: [deviceA],
        services: [weatherService],
      );

      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'dev_a/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(weatherService.messages, isEmpty);
    });
  });
}
