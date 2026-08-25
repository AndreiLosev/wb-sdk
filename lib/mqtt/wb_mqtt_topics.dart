/// Маппинг коротких топиков генератора на пути Wiren Board MQTT.
abstract final class WbMqttTopics {
  static const _devicesPrefix = '/devices/';

  /// Короткий топик → broker (`/devices/...`).
  static String toBrokerTopic(String shortTopic) {
    final parts = shortTopic.split('/');
    if (parts.length < 2) {
      throw ArgumentError.value(shortTopic, 'shortTopic', 'Invalid short topic');
    }

    final device = parts[0];

    if (parts.length == 2 && parts[1] == 'meta') {
      return '$_devicesPrefix$device/meta';
    }

    if (parts.length == 3 && parts[2] == 'meta') {
      return '$_devicesPrefix$device/controls/${parts[1]}/meta';
    }

    final control = parts[1];

    if (parts.length == 3 && parts[2] == 'on') {
      return '$_devicesPrefix$device/controls/$control/on';
    }

    if (parts.length == 2) {
      return '$_devicesPrefix$device/controls/$control';
    }

    throw ArgumentError.value(shortTopic, 'shortTopic', 'Invalid short topic');
  }

  /// Broker топик → короткий топик для `updateField`.
  static String? fromBrokerTopic(String brokerTopic) {
    if (!brokerTopic.startsWith(_devicesPrefix)) {
      return null;
    }

    final rest = brokerTopic.substring(_devicesPrefix.length);
    final parts = rest.split('/');

    if (parts.length == 2 && parts[1] == 'meta') {
      return '${parts[0]}/meta';
    }

    if (parts.length == 4 &&
        parts[1] == 'controls' &&
        parts[3] == 'meta') {
      return '${parts[0]}/${parts[2]}/meta';
    }

    if (parts.length == 4 && parts[1] == 'controls' && parts[3] == 'on') {
      return '${parts[0]}/${parts[2]}/on';
    }

    if (parts.length == 3 && parts[1] == 'controls') {
      return '${parts[0]}/${parts[2]}';
    }

    return null;
  }
}
