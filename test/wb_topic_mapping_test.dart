import 'package:test/test.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  final mapping = WbTopicMapping(
    inputs: {'alias/temp/on': 'dev_a/temp/on'},
    outputs: {'dev_a/lamp/on': 'alias/lamp/on'},
  );

  group('WbTopicMapping.resolveInputTopic', () {
    test('алиас → канонический топик', () {
      expect(mapping.resolveInputTopic('alias/temp/on'), 'dev_a/temp/on');
    });

    test('неизвестный топик без изменений', () {
      expect(mapping.resolveInputTopic('dev_a/temp/on'), 'dev_a/temp/on');
    });
  });

  group('WbTopicMapping.expandOutputTopics', () {
    test('канонический топик → канонический + алиас', () {
      expect(
        mapping.expandOutputTopics('dev_a/lamp/on'),
        ['dev_a/lamp/on', 'alias/lamp/on'],
      );
    });

    test('топик без маппинга → только исходный', () {
      expect(mapping.expandOutputTopics('dev_a/temp/on'), ['dev_a/temp/on']);
    });
  });

  group('WbTopicMapping.inputSubscriptionTopics', () {
    test('возвращает ключи inputs', () {
      expect(mapping.inputSubscriptionTopics, ['alias/temp/on']);
    });

    test('пустой маппинг → пустой список', () {
      expect(WbTopicMapping().inputSubscriptionTopics, isEmpty);
    });
  });

  group('WbTopicMapping.parseIoMappingTopic', () {
    test('разбирает input-топик', () {
      expect(
        WbTopicMapping.parseIoMappingTopic('io_mapping/inputs/alias/temp/on'),
        (isInput: true, key: 'alias/temp/on'),
      );
    });

    test('разбирает output-топик', () {
      expect(
        WbTopicMapping.parseIoMappingTopic('io_mapping/outputs/dev_a/lamp/on'),
        (isInput: false, key: 'dev_a/lamp/on'),
      );
    });

    test('неизвестный топик → null', () {
      expect(
        WbTopicMapping.parseIoMappingTopic('io_mapping/unknown/key'),
        isNull,
      );
    });
  });

  group('WbTopicMapping.applyIoMapping', () {
    test('добавляет запись', () {
      final m = WbTopicMapping();
      expect(
        m.applyIoMapping(
          isInput: true,
          key: 'alias/switch/on',
          value: 'dev_b/switch/on',
        ),
        isTrue,
      );
      expect(m.inputs['alias/switch/on'], 'dev_b/switch/on');
    });

    test('идемпотентен при том же значении', () {
      final m = WbTopicMapping(inputs: {'alias/temp/on': 'dev_a/temp/on'});
      expect(
        m.applyIoMapping(
          isInput: true,
          key: 'alias/temp/on',
          value: 'dev_a/temp/on',
        ),
        isFalse,
      );
    });

    test('удаляет запись при пустом value', () {
      final m = WbTopicMapping(inputs: {'alias/temp/on': 'dev_a/temp/on'});
      expect(
        m.applyIoMapping(isInput: true, key: 'alias/temp/on', value: ''),
        isTrue,
      );
      expect(m.inputs, isEmpty);
    });
  });

  group('WbTopicMapping.load/save', () {
    test('round-trip через storage', () {
      final storage = _FakeStorage();
      mapping.save(storage);

      final loaded = WbTopicMapping();
      loaded.load(storage);

      expect(loaded.inputs, mapping.inputs);
      expect(loaded.outputs, mapping.outputs);
    });

    test('load берёт defaults если storage пуст', () {
      final storage = _FakeStorage();
      final defaults = WbTopicMapping(
        inputs: {'alias/temp/on': 'dev_a/temp/on'},
      );

      final loaded = WbTopicMapping();
      loaded.load(storage, defaults: defaults);

      expect(loaded.inputs, defaults.inputs);
    });

    test('storage перекрывает defaults', () {
      final storage = _FakeStorage();
      storage.put(WbTopicMapping.inputsStorageKey, {
        'stored/alias/on': 'dev_x/sensor/on',
      });

      final loaded = WbTopicMapping();
      loaded.load(
        storage,
        defaults: WbTopicMapping(inputs: {'alias/temp/on': 'dev_a/temp/on'}),
      );

      expect(loaded.inputs, {'stored/alias/on': 'dev_x/sensor/on'});
    });
  });

  group('WbTopicMapping.publishAll', () {
    test('публикует все записи retained', () {
      final mqtt = _FakeMqttClient();
      mapping.publishAll(mqtt);

      expect(
        mqtt.published,
        [
          (
            topic: 'io_mapping/inputs/alias/temp/on',
            payload: 'dev_a/temp/on',
            retained: true,
          ),
          (
            topic: 'io_mapping/outputs/dev_a/lamp/on',
            payload: 'alias/lamp/on',
            retained: true,
          ),
        ],
      );
    });
  });
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

class _FakeMqttClient implements WbMqttClient {
  final published =
      <({String topic, String payload, bool retained})>[];

  @override
  Stream<WbMqttMessage> get messages => const Stream.empty();

  @override
  void publish(String topic, String payload, {bool retained = false}) {
    published.add((topic: topic, payload: payload, retained: retained));
  }

  @override
  void subscribe(String topic) {}

  @override
  void unsubscribe(String topic) {}
}
