import 'package:wb_sdk/contracts/iexternal_service.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';

/// Маршрутизирует MQTT-сообщения во внешние сервисы по [IExternalService.mqttPrefix].
class ExternalServiceRouter {
  ExternalServiceRouter(List<IExternalService> services)
    : _services = List<IExternalService>.from(services)
        ..sort((a, b) => b.mqttPrefix.length.compareTo(a.mqttPrefix.length));

  final List<IExternalService> _services;

  Iterable<String> get subscriptionTopics sync* {
    for (final service in _services) {
      yield '${service.mqttPrefix}#';
      yield* service.dependencies();
    }
  }

  /// Маршрутизирует сообщение, если топик начинается с [IExternalService.mqttPrefix].
  ///
  /// Возвращает `true`, если сообщение обработано.
  bool route(WbMqttMessage message) {
    for (final service in _services) {
      final prefix = service.mqttPrefix;
      if (!message.topic.startsWith(prefix)) {
        continue;
      }
      service.handleMessage(
        WbMqttMessage(
          topic: message.topic.substring(prefix.length),
          payload: message.payload,
        ),
      );
      return true;
    }

    return false;
  }
}
