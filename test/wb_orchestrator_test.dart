import 'dart:async';

import 'package:test/test.dart';
import 'package:wb_annatation/orchestrator/wb_orchestrator.dart';
import 'package:wb_annatation/orchestrator/wb_orchestrator_builder.dart';
import 'package:wb_annatation/wb_annatation.dart';

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

    const topicMapping = WbTopicMapping(
      inputs: {'alias/temp/on': 'dev_a/temp/on'},
      outputs: {'dev_a/lamp/on': 'alias/lamp/on'},
    );

    setUp(() async {
      mqtt = _FakeWbMqttClient(topicMapping: topicMapping);
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
      mqtt.publish('dev_a/lamp/on', '1');

      expect(
        mqtt.publishedTopics,
        ['dev_a/lamp/on', 'alias/lamp/on'],
      );
      expect(mqtt.publishedPayloads, ['1', '1']);
    });
  });
}

class _FakeWbMqttClient implements WbMqttClient {
  _FakeWbMqttClient({this.topicMapping = const WbTopicMapping()});

  final WbTopicMapping topicMapping;
  final _controller = StreamController<WbMqttMessage>.broadcast();
  final subscribedTopics = <String>[];
  final publishedTopics = <String>[];
  final publishedPayloads = <String>[];

  @override
  Stream<WbMqttMessage> get messages => _controller.stream;

  @override
  void publish(String topic, String payload, {bool retained = false}) {
    for (final mappedTopic in topicMapping.expandOutputTopics(topic)) {
      publishedTopics.add(mappedTopic);
      publishedPayloads.add(payload);
    }
  }

  @override
  void subscribe(String topic) {
    subscribedTopics.add(topic);
  }

  @override
  void unsubscribe(String topic) {}

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
