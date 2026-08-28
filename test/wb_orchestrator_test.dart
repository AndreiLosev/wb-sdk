import 'dart:async';

import 'package:test/test.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator_builder.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  group('WbOrchestratorBuilder', () {
    test('test-конструктор возвращает WbOrchestrator', () async {
      final mqtt = _FakeWbMqttClient();

      final orchestrator = await WbOrchestratorBuilder.test(mqtt: mqtt).build(
        devices: [_TestDevice(name: 'dev_a')],
      );

      expect(orchestrator, isA<WbOrchestrator>());
    });

    test('повторный build бросает StateError', () async {
      final mqtt = _FakeWbMqttClient();
      final builder = WbOrchestratorBuilder.test(mqtt: mqtt);

      await builder.build(devices: [_TestDevice(name: 'dev_a')]);

      expect(
        () => builder.build(devices: [_TestDevice(name: 'dev_b')]),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('WbOrchestrator', () {
    late _FakeWbMqttClient mqtt;
    late WbOrchestrator orchestrator;
    late _TestDevice deviceA;
    late _TestDevice deviceB;

    setUp(() async {
      mqtt = _FakeWbMqttClient();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'dev_a/temp/on'},
        outputs: {'dev_a/lamp/on'},
      );
      deviceB = _TestDevice(
        name: 'dev_b',
        inputs: {'dev_b/switch/on'},
        outputs: {},
      );
      orchestrator = await WbOrchestratorBuilder.test(mqtt: mqtt).build(
        devices: [deviceA, deviceB],
      );
    });

    test('input-топик вызывает updateField и execute', () {
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'dev_a/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('output-топик вызывает только updateField', () {
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'dev_a/lamp/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 0);
    });

    test('неизвестный топик игнорируется', () {
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'unknown/topic/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 0);
      expect(deviceA.executeCalls, 0);
      expect(deviceB.updateFieldCalls, 0);
      expect(deviceB.executeCalls, 0);
    });

    test('сообщение маршрутизируется в правильное устройство', () {
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'dev_b/switch/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 0);
      expect(deviceB.updateFieldCalls, 1);
      expect(deviceB.executeCalls, 1);
    });

    test('prepareForTest вызывает init и subscribe', () {
      orchestrator.prepareForTest();

      expect(deviceA.initCalls, 1);
      expect(deviceB.initCalls, 1);
      expect(mqtt.subscribedTopics, containsAll([
        'dev_a/temp/on',
        'dev_a/lamp/on',
        'dev_b/switch/on',
        'debug/dev_a',
        'debug/dev_b',
      ]));
    });

    test('повторный run бросает StateError', () async {
      final runFuture = orchestrator.run();
      await Future<void>.delayed(Duration.zero);

      expect(
        () => orchestrator.run(),
        throwsA(isA<StateError>()),
      );

      await mqtt.close();
      await runFuture;
    });
  });

  group('WbTopicMapping integration', () {
    late _FakeWbMqttClient mqtt;
    late WbOrchestrator orchestrator;
    late _TestDevice deviceA;

    final topicMapping = WbTopicMapping(
      inputs: {'alias/temp/on': 'dev_a/temp/on'},
      outputs: {'dev_a/lamp/on': 'alias/lamp/on'},
    );

    setUp(() async {
      mqtt = _FakeWbMqttClient();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'dev_a/temp/on'},
        outputs: {'dev_a/lamp/on'},
      );
      orchestrator = await WbOrchestratorBuilder.test(
        mqtt: mqtt,
        topicMapping: topicMapping,
      ).build(devices: [deviceA]);
    });

    test('алиас input-топика вызывает updateField и execute', () {
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'alias/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('prepareForTest подписывается на алиас input-топика', () {
      orchestrator.prepareForTest();

      expect(mqtt.subscribedTopics, contains('alias/temp/on'));
    });

    test('публикация в канонический output-топик дублируется в алиас', () {
      wbPublish('dev_a/lamp/on', '1');

      expect(
        mqtt.publishedTopics,
        ['dev_a/lamp/on', 'alias/lamp/on'],
      );
      expect(mqtt.publishedPayloads, ['1', '1']);
    });
  });

  group('WbTopicMapping io_mapping sync', () {
    late _FakeWbMqttClient mqtt;
    late _FakeStorage storage;
    late WbOrchestrator orchestrator;
    late _TestDevice deviceA;

    setUp(() async {
      mqtt = _FakeWbMqttClient();
      storage = _FakeStorage();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'dev_a/temp/on'},
        outputs: {'dev_a/lamp/on'},
      );
      orchestrator = await WbOrchestratorBuilder.test(
        mqtt: mqtt,
        storage: storage,
        topicMapping: WbTopicMapping(
          inputs: {'alias/temp/on': 'dev_a/temp/on'},
        ),
      ).build(devices: [deviceA]);
    });

    test('prepareForTest публикует и подписывается на io_mapping', () {
      orchestrator.prepareForTest();

      expect(
        mqtt.subscribedTopics,
        containsAll(WbTopicMapping.ioMappingSubscriptionTopics),
      );
      expect(
        mqtt.publishedTopics,
        contains('io_mapping/inputs/alias/temp/on'),
      );
      expect(mqtt.publishedPayloads, contains('dev_a/temp/on'));
    });

    test('io_mapping input обновляет маппинг, сохраняет и подписывается', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/new_alias/temp/on',
          payload: 'dev_a/temp/on',
        ),
      );

      expect(storage.get(WbTopicMapping.inputsStorageKey, null), {
        'alias/temp/on': 'dev_a/temp/on',
        'new_alias/temp/on': 'dev_a/temp/on',
      });
      expect(mqtt.subscribedTopics, contains('new_alias/temp/on'));
    });

    test('сообщение на динамический алиас маршрутизируется в устройство', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/new_alias/temp/on',
          payload: 'dev_a/temp/on',
        ),
      );
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'new_alias/temp/on', payload: '22.0'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('пустой payload удаляет input и отписывается от алиаса', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/alias/temp/on',
          payload: '',
        ),
      );

      expect(
        storage.get(WbTopicMapping.inputsStorageKey, null),
        <String, String>{},
      );
      expect(mqtt.unsubscribedTopics, contains('alias/temp/on'));
    });
  });

  group('WbDebugLog integration', () {
    late _FakeWbMqttClient mqtt;
    late WbOrchestrator orchestrator;

    setUp(() async {
      mqtt = _FakeWbMqttClient();
      orchestrator = await WbOrchestratorBuilder.test(mqtt: mqtt).build(
        devices: [_TestDevice(name: 'dev_a')],
      );
    });

    test('wbDebugLog публикует после включения флага', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '1'),
      );
      wbDebugLog('dev_a', 'debug message');

      expect(mqtt.publishedTopics.length, 1);
      expect(mqtt.publishedTopics.first, startsWith('debug/dev_a/'));
      expect(mqtt.publishedPayloads, ['debug message']);
    });

    test('wbDebugLog молчит после выключения флага', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '1'),
      );
      wbDebugLog('dev_a', 'first');
      orchestrator.dispatchMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '0'),
      );
      wbDebugLog('dev_a', 'second');

      expect(mqtt.publishedTopics.length, 1);
      expect(mqtt.publishedPayloads, ['first']);
    });

    test('сообщения debug/dev_a/timestamp игнорируются', () {
      orchestrator.prepareForTest();

      orchestrator.dispatchMessage(
        const WbMqttMessage(
          topic: 'debug/dev_a/2024-08-28T17:39:00.123',
          payload: '1',
        ),
      );
      wbDebugLog('dev_a', 'msg');

      expect(mqtt.publishedTopics, isEmpty);
    });
  });
}

class _FakeWbMqttClient implements WbMqttClient {
  final _controller = StreamController<WbMqttMessage>.broadcast();
  final subscribedTopics = <String>[];
  final unsubscribedTopics = <String>[];
  final publishedTopics = <String>[];
  final publishedPayloads = <String>[];

  @override
  Stream<WbMqttMessage> get messages => _controller.stream;

  @override
  void publish(String topic, String payload, {bool retained = false}) {
    publishedTopics.add(topic);
    publishedPayloads.add(payload);
  }

  @override
  void subscribe(String topic) {
    subscribedTopics.add(topic);
  }

  @override
  void unsubscribe(String topic) {
    unsubscribedTopics.add(topic);
  }

  void emit(WbMqttMessage message) {
    _controller.add(message);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

class _TestDevice implements IDevice {
  _TestDevice({
    required this.name,
    Set<String>? inputs,
    Set<String>? outputs,
  }) : _inputs = inputs ?? const {},
       _outputs = outputs ?? const {};

  @override
  final String name;

  @override
  final WbLocalizedTitle? title = null;

  final Set<String> _inputs;
  final Set<String> _outputs;

  int initCalls = 0;
  int updateFieldCalls = 0;
  int executeCalls = 0;
  WbMqttMessage? lastMessage;

  @override
  void execute() {
    executeCalls++;
  }

  @override
  void init() {
    initCalls++;
  }

  @override
  Set<String> inputs() => _inputs;

  @override
  Set<String> outputs() => _outputs;

  @override
  void updateField(WbMqttMessage mess) {
    updateFieldCalls++;
    lastMessage = mess;
  }
}

class _FakeStorage implements WbStorage {
  final _data = <String, Object?>{};

  @override
  Object? get(String key, Object? defaultValue) => _data[key] ?? defaultValue;

  @override
  void put(String key, Object? value) {
    _data[key] = value;
  }
}
