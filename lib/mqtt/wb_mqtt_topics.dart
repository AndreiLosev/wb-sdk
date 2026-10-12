import 'package:meta/meta.dart';

/// Маппинг коротких топиков генератора на пути Wiren Board MQTT.
abstract final class WbMqttTopics {
  static const _devicesPrefix = '/devices/';
  static const _ioMappingPrefix = 'io_mapping/';
  static const _debugPrefix = 'debug/';

  static final _externalPrefixes = <String>{};

  /// Глобальные подписки на meta/error всех устройств и контролов.
  static const errorSubscriptionTopics = [
    '+/+/meta/error',
    '+/meta/error',
  ];

  /// Регистрирует префиксы внешних сервисов для passthrough-маппинга.
  static void registerExternalPrefixes(Iterable<String> prefixes) {
    _externalPrefixes
      ..clear()
      ..addAll(prefixes);
  }

  /// Сбрасывает зарегистрированные префиксы внешних сервисов.
  @visibleForTesting
  static void clearExternalPrefixes() {
    _externalPrefixes.clear();
  }

  /// Короткий топик → broker (`/devices/...`, `/io_mapping/...` или `/debug/...`).
  static String toBrokerTopic(String shortTopic) {
    if (_isPassthroughTopic(shortTopic)) {
      return '/$shortTopic';
    }

    if (shortTopic == errorSubscriptionTopics[0]) {
      return '/devices/+/controls/+/meta/error';
    }
    if (shortTopic == errorSubscriptionTopics[1]) {
      return '/devices/+/meta/error';
    }

    final parts = shortTopic.split('/');
    if (parts.length < 2) {
      throw ArgumentError.value(shortTopic, 'shortTopic', 'Invalid short topic');
    }

    final device = parts[0];

    if (parts.length == 4 && parts[2] == 'meta' && parts[3] == 'error') {
      return '$_devicesPrefix$device/controls/${parts[1]}/meta/error';
    }

    if (parts.length == 3 && parts[1] == 'meta' && parts[2] == 'error') {
      return '$_devicesPrefix$device/meta/error';
    }

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
    if (brokerTopic.startsWith('/')) {
      final short = brokerTopic.substring(1);
      if (_isPassthroughTopic(short)) {
        return short;
      }
    }

    if (!brokerTopic.startsWith(_devicesPrefix)) {
      return null;
    }

    final rest = brokerTopic.substring(_devicesPrefix.length);
    final parts = rest.split('/');

    if (parts.length == 5 &&
        parts[1] == 'controls' &&
        parts[3] == 'meta' &&
        parts[4] == 'error') {
      return '${parts[0]}/${parts[2]}/meta/error';
    }

    if (parts.length == 3 && parts[1] == 'meta' && parts[2] == 'error') {
      return '${parts[0]}/meta/error';
    }

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

  static bool _isPassthroughTopic(String shortTopic) {
    if (shortTopic.startsWith(_ioMappingPrefix) ||
        shortTopic.startsWith(_debugPrefix)) {
      return true;
    }

    return _matchesExternalPrefix(shortTopic);
  }

  static bool _matchesExternalPrefix(String shortTopic) {
    for (final prefix in _externalPrefixes) {
      if (shortTopic.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
