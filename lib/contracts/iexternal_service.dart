import 'package:wb_sdk/contracts/wb_mqtt_client.dart';

/// Внешний MQTT-сервис с собственным namespace.
///
/// Оркестратор автоматически подписывается на `{mqttPrefix}#` и [dependencies],
/// а в [handleMessage] передаёт топик без [mqttPrefix] и сырой payload.
abstract class IExternalService {
  /// Короткий MQTT-префикс, например `weather/`.
  ///
  /// Обязан заканчиваться на `/`.
  String get mqttPrefix;

  /// Дополнительные топики для подписки (вне `{mqttPrefix}#`).
  Set<String> dependencies();

  /// [message.topic] — относительный путь без [mqttPrefix].
  /// [message.payload] — сырой MQTT payload.
  void handleMessage(WbMqttMessage message);
}
