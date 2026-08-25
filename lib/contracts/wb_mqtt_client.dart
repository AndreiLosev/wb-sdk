/// Входящее MQTT-сообщение.
class WbMqttMessage {
  const WbMqttMessage({required this.topic, required this.payload});

  final String topic;
  final String payload;
}

/// Абстракция MQTT-транспорта для WB-драйверов.
///
/// Реализацию (обёртку над mqtt_client, Mosquitto и т.д.)
/// пишет потребитель пакета.
abstract interface class WbMqttClient {
  /// Публикация payload в [topic].
  /// Для meta и текущих значений контролов — [retained: true].
  void publish(String topic, String payload, {bool retained = false});

  /// Подписка на топик.
  void subscribe(String topic);

  /// Отписка (вызывается из `dispose()` сгенерированного драйвера).
  void unsubscribe(String topic);

  /// Поток входящих сообщений после [subscribe].
  Stream<WbMqttMessage> get messages;
}
