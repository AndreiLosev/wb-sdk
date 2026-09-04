import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  group('WbOrchestrator', () {
    late _FakeWbMqttClient mqtt;
    late WbOrchestrator orchestrator;
    late _TestDevice deviceA;
    late _TestDevice deviceB;

    setUp(() {
      mqtt = _FakeWbMqttClient();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'temp/on'},
        outputs: {'lamp/on'},
      );
      deviceB = _TestDevice(
        name: 'dev_b',
        inputs: {'switch/on'},
        outputs: {},
      );
      orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        devices: [deviceA, deviceB],
      );
    });

    test('input-топик вызывает updateField и execute', () {
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'dev_a/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('output-топик вызывает только updateField', () {
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'dev_a/lamp/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 0);
    });

    test('неизвестный топик игнорируется', () {
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'unknown/topic/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 0);
      expect(deviceA.executeCalls, 0);
      expect(deviceB.updateFieldCalls, 0);
      expect(deviceB.executeCalls, 0);
    });

    test('сообщение маршрутизируется в правильное устройство', () {
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'dev_b/switch/on', payload: '1'),
      );

      expect(deviceA.updateFieldCalls, 0);
      expect(deviceB.updateFieldCalls, 1);
      expect(deviceB.executeCalls, 1);
    });

    test('prepare публикует meta, восстанавливает retains, вызывает execute и subscribe', () {
      fakeAsync((async) {
        final storage = _FakeStorage();
        storage.put('dev_a.mode', '1');
        final retainDevice = _TestDevice(
          name: 'dev_a',
          inputs: {'temp/on'},
          outputs: {'lamp/on'},
          meta: {
            'lamp': ControlMeta(
              type: WbControlType.switch_,
              title: WbLocalizedTitle(en: 'Lamp'),
            ),
            'mode': ControlMeta(
              type: WbControlType.text,
              title: WbLocalizedTitle(en: 'Mode'),
            ),
          },
          retains: {'mode': '0'},
        );
        final mqtt = _FakeWbMqttClient();
        final orchestrator = WbOrchestrator.assemble(
          mqtt: mqtt,
          storage: storage,
          devices: [retainDevice, deviceB],
        );

        orchestrator.prepare();

        expect(
          mqtt.publishedTopics,
          containsAll([
            'dev_a/meta',
            'dev_a/lamp/meta',
          ]),
        );
        expect(
          mqtt.publishedPayloads,
          contains(contains('"driver":"vktmotage"')),
        );
        expect(mqtt.subscribedTopics, containsAll([
          'dev_a/temp/on',
          'dev_a/lamp/on',
          'dev_b/switch/on',
          'debug/dev_a',
          'debug/dev_b',
        ]));

        async.elapse(const Duration(seconds: 1));

        expect(retainDevice.updateFieldCalls, 1);
        expect(retainDevice.lastMessage?.topic, 'dev_a/mode/on');
        expect(retainDevice.lastMessage?.payload, '1');
        expect(retainDevice.executeCalls, 1);
        expect(deviceB.executeCalls, 1);
      });
    });

    test('prepare бросает StateError если retain без meta', () async {
      final storage = _FakeStorage();
      final retainDevice = _TestDevice(
        name: 'dev_a',
        retains: {'mode': '0'},
      );
      final orchestrator = WbOrchestrator.assemble(
        mqtt: _FakeWbMqttClient(),
        storage: storage,
        devices: [retainDevice],
      );

      final errors = <Object>[];
      final done = Completer<void>();

      runZonedGuarded(
        () {
          orchestrator.prepare();
          Timer(const Duration(milliseconds: 1100), () {
            if (!done.isCompleted) {
              done.complete();
            }
          });
        },
        (error, stack) {
          errors.add(error);
          if (!done.isCompleted) {
            done.complete();
          }
        },
      );

      await done.future;
      expect(errors, hasLength(1));
      expect(errors.first, isA<StateError>());
    });

    test('повторный run бросает StateError', () async {
      final runFuture = orchestrator.run();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await expectLater(
        orchestrator.run(),
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
      inputs: {'alias/temp/on': {'dev_a/temp/on'}},
      outputs: {'dev_a/lamp/on': {'alias/lamp/on'}},
    );

    setUp(() {
      mqtt = _FakeWbMqttClient();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'temp/on'},
        outputs: {'lamp/on'},
      );
      orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        defaults: topicMapping,
        devices: [deviceA],
      );
    });

    test('алиас input-топика вызывает updateField и execute', () {
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'alias/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('prepare подписывается на алиас input-топика', () {
      orchestrator.prepare();

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

    test('алиас с несколькими каноническими топиками обновляет все устройства', () {
      final deviceB = _TestDevice(
        name: 'dev_b',
        inputs: {'temp/on'},
      );
      final multiMapping = WbTopicMapping(
        inputs: {
          'alias/temp/on': {'dev_a/temp/on', 'dev_b/temp/on'},
        },
      );
      final multiOrchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        defaults: multiMapping,
        devices: [deviceA, deviceB],
      );

      multiOrchestrator.handleMessage(
        const WbMqttMessage(topic: 'alias/temp/on', payload: '21.5'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
      expect(deviceB.updateFieldCalls, 1);
      expect(deviceB.executeCalls, 1);
      expect(deviceB.lastMessage?.topic, 'dev_b/temp/on');
    });
  });

  group('WbTopicMapping io_mapping sync', () {
    late _FakeWbMqttClient mqtt;
    late _FakeStorage storage;
    late WbOrchestrator orchestrator;
    late _TestDevice deviceA;

    setUp(() {
      mqtt = _FakeWbMqttClient();
      storage = _FakeStorage();
      deviceA = _TestDevice(
        name: 'dev_a',
        inputs: {'temp/on'},
        outputs: {'lamp/on'},
      );
      orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        storage: storage,
        defaults: WbTopicMapping(
          inputs: {'alias/temp/on': {'dev_a/temp/on'}},
        ),
        devices: [deviceA],
      );
    });

    test('prepare публикует и подписывается на io_mapping', () {
      orchestrator.prepare();

      expect(
        mqtt.subscribedTopics,
        containsAll(WbTopicMapping.ioMappingSubscriptionTopics),
      );
      expect(
        mqtt.publishedTopics,
        contains('io_mapping/inputs/alias/temp/on'),
      );
      expect(mqtt.publishedPayloads, contains('["dev_a/temp/on"]'));
    });

    test('io_mapping input обновляет маппинг, сохраняет и подписывается', () {
      orchestrator.prepare();

      orchestrator.handleMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/new_alias/temp/on',
          payload: 'dev_a/temp/on',
        ),
      );

      expect(storage.get(WbTopicMapping.inputsStorageKey, null), {
        'alias/temp/on': ['dev_a/temp/on'],
        'new_alias/temp/on': ['dev_a/temp/on'],
      });
      expect(mqtt.subscribedTopics, contains('new_alias/temp/on'));
    });

    test('сообщение на динамический алиас маршрутизируется в устройство', () {
      orchestrator.prepare();
      deviceA.updateFieldCalls = 0;
      deviceA.executeCalls = 0;

      orchestrator.handleMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/new_alias/temp/on',
          payload: 'dev_a/temp/on',
        ),
      );
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'new_alias/temp/on', payload: '22.0'),
      );

      expect(deviceA.updateFieldCalls, 1);
      expect(deviceA.executeCalls, 1);
      expect(deviceA.lastMessage?.topic, 'dev_a/temp/on');
    });

    test('пустой payload удаляет input и отписывается от алиаса', () {
      orchestrator.prepare();

      orchestrator.handleMessage(
        const WbMqttMessage(
          topic: 'io_mapping/inputs/alias/temp/on',
          payload: '',
        ),
      );

      expect(
        storage.get(WbTopicMapping.inputsStorageKey, null),
        <String, List<String>>{},
      );
      expect(mqtt.unsubscribedTopics, contains('alias/temp/on'));
    });
  });

  group('WbDebugLog integration', () {
    late _FakeWbMqttClient mqtt;
    late WbOrchestrator orchestrator;

    setUp(() {
      mqtt = _FakeWbMqttClient();
      orchestrator = WbOrchestrator.assemble(
        mqtt: mqtt,
        devices: [_TestDevice(name: 'dev_a')],
      );
    });

    test('wbDebugLog публикует после включения флага', () {
      orchestrator.prepare();

      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '1'),
      );
      wbDebugLog('dev_a', 'debug message');

      final debugTopics = mqtt.publishedTopics
          .where((topic) => topic.startsWith('debug/dev_a/'))
          .toList();
      expect(debugTopics.length, 1);
      expect(debugTopics.first, startsWith('debug/dev_a/'));
      expect(mqtt.publishedPayloads.last, 'debug message');
    });

    test('wbDebugLog молчит после выключения флага', () {
      orchestrator.prepare();

      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '1'),
      );
      wbDebugLog('dev_a', 'first');
      orchestrator.handleMessage(
        const WbMqttMessage(topic: 'debug/dev_a', payload: '0'),
      );
      wbDebugLog('dev_a', 'second');

      final debugTopics = mqtt.publishedTopics
          .where((topic) => topic.startsWith('debug/dev_a/'))
          .toList();
      expect(debugTopics.length, 1);
      expect(mqtt.publishedPayloads.last, 'first');
    });

    test('сообщения debug/dev_a/timestamp игнорируются', () {
      orchestrator.prepare();

      orchestrator.handleMessage(
        const WbMqttMessage(
          topic: 'debug/dev_a/2024-08-28T17:39:00.123',
          payload: '1',
        ),
      );
      wbDebugLog('dev_a', 'msg');

      final debugTopics = mqtt.publishedTopics
          .where((topic) => topic.startsWith('debug/dev_a/'))
          .toList();
      expect(debugTopics, isEmpty);
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

final class _TestDevice extends IDevice {
  _TestDevice({
    required this.name,
    Set<String>? inputs,
    Set<String>? outputs,
    Map<String, ControlMeta>? meta,
    Map<String, Object?>? retains,
  }) {
    register(
      _TestDevicePart(
        inputs: inputs ?? const {},
        outputs: outputs ?? const {},
        meta: meta ?? const {},
        retains: retains ?? const {},
      ),
    );
  }

  @override
  final String name;

  @override
  final WbLocalizedTitle? title = null;

  int updateFieldCalls = 0;
  int executeCalls = 0;
  WbMqttMessage? lastMessage;

  @override
  void execute() {
    executeCalls++;
  }

  @override
  void updateField(WbMqttMessage mess) {
    updateFieldCalls++;
    lastMessage = mess;
  }
}

final class _TestDevicePart extends PartOfIDevice {
  _TestDevicePart({
    required this.inputs,
    required this.outputs,
    required this.meta,
    required this.retains,
  });

  final Set<String> inputs;
  final Set<String> outputs;
  final Map<String, ControlMeta> meta;
  final Map<String, Object?> retains;

  @override
  Set<String> addInputs() => inputs;

  @override
  Set<String> addOutputs() => outputs;

  @override
  Map<String, ControlMeta> addMeta() => meta;

  @override
  Map<String, Object?> addRetains() => retains;
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
