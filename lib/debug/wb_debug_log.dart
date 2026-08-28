import 'package:wb_sdk/contracts/wb_mqtt_client.dart';

late void Function(String deviceName, String message) wbDebugLog;

/// Публикует debug-логи в MQTT при включённом флаге `debug/<device_name>`.
class WbDebugLog {
  WbDebugLog({required WbMqttClient mqtt}) : _mqtt = mqtt;

  final WbMqttClient _mqtt;
  final Map<String, bool> _enabled = {};

  static String flagTopic(String deviceName) => 'debug/$deviceName';

  static String messageTopic(String deviceName, DateTime time) =>
      'debug/$deviceName/${time.toIso8601String()}';

  static Set<String> subscriptionTopics(Set<String> deviceNames) =>
      deviceNames.map(flagTopic).toSet();

  bool isEnabled(String deviceName) => _enabled[deviceName] ?? false;

  void updateFlag(String deviceName, String payload) {
    _enabled[deviceName] = _parseDebugFlag(payload);
  }

  void log(String deviceName, String message) {
    if (!isEnabled(deviceName)) {
      return;
    }
    _mqtt.publish(
      messageTopic(deviceName, DateTime.timestamp()),
      message,
      retained: false,
    );
  }

  static bool _parseDebugFlag(String payload) {
    final normalized = payload.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}
