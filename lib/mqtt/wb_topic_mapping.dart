import 'dart:convert';

import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';

/// Результат разбора топика `io_mapping/inputs|outputs/...`.
typedef IoMappingTopic = ({bool isInput, String key});

/// Маппинг коротких топиков `{device}/{control}` на алиасы.
///
/// [inputs] — входящие алиасы: сообщение на ключ обрабатывается как на значения.
/// [outputs] — исходящие алиасы: публикация в ключ дублируется в значения.
class WbTopicMapping {
  WbTopicMapping({Map<String, Set<String>>? inputs, Map<String, Set<String>>? outputs})
    : inputs = _copyMapOfSets(inputs),
      outputs = _copyMapOfSets(outputs);

  static const inputsStorageKey = 'io_mapping_inputs';
  static const outputsStorageKey = 'io_mapping_outputs';

  static const _inputsPrefix = 'io_mapping/inputs/';
  static const _outputsPrefix = 'io_mapping/outputs/';

  final Map<String, Set<String>> inputs;
  final Map<String, Set<String>> outputs;

  /// Топики для подписки на изменения маппинга.
  static const ioMappingSubscriptionTopics = [
    'io_mapping/inputs/#',
    'io_mapping/outputs/#',
  ];

  /// Загружает маппинг из [storage]; при отсутствии данных берёт [defaults].
  void load(WbStorage storage, {WbTopicMapping? defaults}) {
    final storedInputs = storage.get(inputsStorageKey, null);
    final storedOutputs = storage.get(outputsStorageKey, null);

    if (storedInputs is Map) {
      inputs
        ..clear()
        ..addAll(_loadMapFromStorage(storedInputs));
    } else if (defaults != null) {
      inputs
        ..clear()
        ..addAll(_copyMapOfSets(defaults.inputs));
    }

    if (storedOutputs is Map) {
      outputs
        ..clear()
        ..addAll(_loadMapFromStorage(storedOutputs));
    } else if (defaults != null) {
      outputs
        ..clear()
        ..addAll(_copyMapOfSets(defaults.outputs));
    }
  }

  /// Сохраняет обе мапы в [storage].
  void save(WbStorage storage) {
    storage.put(inputsStorageKey, _serializeMap(inputs));
    storage.put(outputsStorageKey, _serializeMap(outputs));
  }

  /// Публикует все записи маппинга в MQTT (retained).
  void publishAll(WbMqttClient mqtt, {bool retained = true}) {
    for (final entry in inputs.entries) {
      mqtt.publish(
        _inputTopic(entry.key),
        jsonEncode(entry.value.toList()),
        retained: retained,
      );
    }
    for (final entry in outputs.entries) {
      mqtt.publish(
        _outputTopic(entry.key),
        jsonEncode(entry.value.toList()),
        retained: retained,
      );
    }
  }

  /// Разбирает топик `io_mapping/inputs|outputs/$key`.
  static IoMappingTopic? parseIoMappingTopic(String topic) {
    if (topic.startsWith(_inputsPrefix)) {
      final key = topic.substring(_inputsPrefix.length);
      if (key.isEmpty) return null;
      return (isInput: true, key: key);
    }

    if (topic.startsWith(_outputsPrefix)) {
      final key = topic.substring(_outputsPrefix.length);
      if (key.isEmpty) return null;
      return (isInput: false, key: key);
    }

    return null;
  }

  /// Обновляет или удаляет запись маппинга. Пустой [value] — удаление.
  /// [value] — JSON-массив строк или одиночный топик.
  /// Возвращает `true`, если маппинг изменился.
  bool applyIoMapping({
    required bool isInput,
    required String key,
    required String value,
  }) {
    final map = isInput ? inputs : outputs;

    if (value.isEmpty) {
      return map.remove(key) != null;
    }

    final parsed = _parsePayloadSet(value);
    final previous = map[key];
    if (previous != null && _setsEqual(previous, parsed)) {
      return false;
    }

    map[key] = parsed;
    return true;
  }

  /// Алиас входящего топика → канонические топики устройств.
  Iterable<String> resolveInputTopics(String topic) {
    final aliases = inputs[topic];
    if (aliases == null) {
      return [topic];
    }

    return aliases.map(resolveAlias);
  }

  /// Топики для публикации: [topic] и дополнительные из [outputs], если есть.
  List<String> expandOutputTopics(String topic) {
    final aliases = outputs[topic];
    if (aliases == null || aliases.isEmpty) {
      return [topic];
    }
    return [topic, ...aliases.map(resolveAlias)];
  }

  String resolveAlias(String alias) =>
      alias.endsWith('on') ? alias : "$alias/on";

  /// Дополнительные топики для подписки (ключи [inputs]).
  Iterable<String> get inputSubscriptionTopics => inputs.keys;

  static String _inputTopic(String key) => '$_inputsPrefix$key';

  static String _outputTopic(String key) => '$_outputsPrefix$key';

  static Map<String, Set<String>> _copyMapOfSets(Map<String, Set<String>>? source) {
    if (source == null) {
      return {};
    }
    return {for (final entry in source.entries) entry.key: Set.of(entry.value)};
  }

  static Map<String, List<String>> _serializeMap(Map<String, Set<String>> map) {
    return {for (final entry in map.entries) entry.key: entry.value.toList()};
  }

  static Map<String, Set<String>> _loadMapFromStorage(Map<dynamic, dynamic> stored) {
    final result = <String, Set<String>>{};
    for (final entry in stored.entries) {
      final key = entry.key as String;
      final value = entry.value;
      if (value is List) {
        result[key] = Set<String>.from(value.cast<String>());
      } else if (value is String) {
        result[key] = {value};
      }
    }
    return result;
  }

  static Set<String> _parsePayloadSet(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return Set<String>.from(decoded.cast<String>());
      }
    } on FormatException {
      // fallback to single topic
    }
    return {value};
  }

  static bool _setsEqual(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }
}
