import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/iexternal_service.dart';
import 'package:wb_sdk/mqtt/wb_mqtt_topics.dart';

/// Валидация [IExternalService] при сборке оркестратора.
abstract final class ExternalServiceRegistry {
  static const reservedPrefixes = {
    'io_mapping/',
    'debug/',
    'devices/',
  };

  static void validate(
    List<IExternalService> services,
    List<IDevice> devices,
  ) {
    final prefixes = <String>[];

    for (final service in services) {
      final prefix = service.mqttPrefix;
      _validatePrefixFormat(prefix);
      _validateNotReserved(prefix);
      prefixes.add(prefix);
    }

    _validateNoPrefixOverlap(prefixes);
    _validateNoDeviceCollision(prefixes, devices);

    WbMqttTopics.registerExternalPrefixes(prefixes);
  }

  static void _validatePrefixFormat(String prefix) {
    if (prefix.isEmpty) {
      throw ArgumentError.value(prefix, 'mqttPrefix', 'must not be empty');
    }
    if (!prefix.endsWith('/')) {
      throw ArgumentError.value(
        prefix,
        'mqttPrefix',
        'must end with "/"',
      );
    }
  }

  static void _validateNotReserved(String prefix) {
    for (final reserved in reservedPrefixes) {
      if (prefix == reserved || prefix.startsWith(reserved)) {
        throw ArgumentError.value(
          prefix,
          'mqttPrefix',
          'conflicts with reserved prefix "$reserved"',
        );
      }
    }
  }

  static void _validateNoPrefixOverlap(List<String> prefixes) {
    for (var i = 0; i < prefixes.length; i++) {
      for (var j = i + 1; j < prefixes.length; j++) {
        final a = prefixes[i];
        final b = prefixes[j];
        if (a.startsWith(b) || b.startsWith(a)) {
          throw ArgumentError(
            'External service prefixes overlap: "$a" and "$b"',
          );
        }
      }
    }
  }

  static void _validateNoDeviceCollision(
    List<String> prefixes,
    List<IDevice> devices,
  ) {
    for (final device in devices) {
      final devicePrefix = '${device.name}/';
      for (final prefix in prefixes) {
        if (prefix == devicePrefix ||
            prefix.startsWith(devicePrefix) ||
            devicePrefix.startsWith(prefix)) {
          throw ArgumentError(
            'External service prefix "$prefix" conflicts with device "${device.name}"',
          );
        }
      }
    }
  }
}
