import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';

/// Результат разбора топика `io_mapping/inputs|outputs/...`.
typedef IoMappingTopic = ({bool isInput, String key});

/// Маппинг коротких топиков `{device}/{control}` на алиасы.
///
/// [inputs] — входящие алиасы: сообщение на ключ обрабатывается как на значение.
/// [outputs] — исходящие алиасы: публикация в ключ дублируется в значение.
class WbTopicMapping {
  WbTopicMapping({Map<String, String>? inputs, Map<String, String>? outputs})
    : inputs = Map.of(inputs ?? {}),
      outputs = Map.of(outputs ?? {});

  static const inputsStorageKey = 'io_mapping_inputs';
  static const outputsStorageKey = 'io_mapping_outputs';

  static const _inputsPrefix = 'io_mapping/inputs/';
  static const _outputsPrefix = 'io_mapping/outputs/';

  final Map<String, String> inputs;
  final Map<String, String> outputs;

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
        ..addAll(Map<String, String>.from(storedInputs));
    } else if (defaults != null) {
      inputs
        ..clear()
        ..addAll(defaults.inputs);
    }

    if (storedOutputs is Map) {
      outputs
        ..clear()
        ..addAll(Map<String, String>.from(storedOutputs));
    } else if (defaults != null) {
      outputs
        ..clear()
        ..addAll(defaults.outputs);
    }
  }

  /// Сохраняет обе мапы в [storage].
  void save(WbStorage storage) {
    storage.put(inputsStorageKey, Map<String, String>.from(inputs));
    storage.put(outputsStorageKey, Map<String, String>.from(outputs));
  }

  /// Публикует все записи маппинга в MQTT (retained).
  void publishAll(WbMqttClient mqtt, {bool retained = true}) {
    for (final entry in inputs.entries) {
      mqtt.publish(_inputTopic(entry.key), entry.value, retained: retained);
    }
    for (final entry in outputs.entries) {
      mqtt.publish(_outputTopic(entry.key), entry.value, retained: retained);
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

    final previous = map[key];
    if (previous == value) {
      return false;
    }

    map[key] = value;
    return true;
  }

  /// Алиас входящего топика → канонический топик устройства.
  String resolveInputTopic(String topic) {
    final alias = inputs[topic];
    if (alias == null) return topic;

    return resolveAlias(alias);
  }

  /// Топики для публикации: [topic] и дополнительный из [outputs], если есть.
  List<String> expandOutputTopics(String topic) {
    final alias = outputs[topic];
    if (alias == null) {
      return [topic];
    }
    return [topic, resolveAlias(alias)];
  }

  String resolveAlias(String alias) =>
      alias.endsWith('on') ? alias : "$alias/on";

  /// Дополнительные топики для подписки (ключи [inputs]).
  Iterable<String> get inputSubscriptionTopics => inputs.keys;

  static String _inputTopic(String key) => '$_inputsPrefix$key';

  static String _outputTopic(String key) => '$_outputsPrefix$key';
}
