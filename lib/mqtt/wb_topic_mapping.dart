/// Маппинг коротких топиков `{device}/{control}` на алиасы.
///
/// [inputs] — входящие алиасы: сообщение на ключ обрабатывается как на значение.
/// [outputs] — исходящие алиасы: публикация в ключ дублируется в значение.
class WbTopicMapping {
  const WbTopicMapping({this.inputs = const {}, this.outputs = const {}});

  final Map<String, String> inputs;
  final Map<String, String> outputs;

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
}
