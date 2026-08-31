import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';

class TopicRoute {
  const TopicRoute({required this.device, required this.isInput});

  final IDevice device;
  final bool isInput;
}

class DeviceTopicRouter {
  DeviceTopicRouter._(this._routes) {
    _genericTopics = _makeGenericTopick();
  }

  factory DeviceTopicRouter.fromDevices(List<IDevice> devices) {
    final routes = <String, TopicRoute>{};

    for (final device in devices) {
      for (final topic in device.inputs()) {
        routes['${device.name}/$topic'] = TopicRoute(
          device: device,
          isInput: true,
        );
      }
      for (final topic in device.outputs()) {
        routes['${device.name}/$topic'] = TopicRoute(
          device: device,
          isInput: false,
        );
      }
    }

    return DeviceTopicRouter._(routes);
  }

  final Map<String, TopicRoute> _routes;
  late final Map<String, RegExp> _genericTopics;

  Iterable<String> get topics => _routes.keys;

  void route(WbMqttMessage message, WbTopicMapping topicMapping) {
    final topic = topicMapping.resolveInputTopic(message.topic);
    final route = _routes[topic] ?? _resolveGenericTopic(topic);

    if (route == null) {
      return;
    }
    route.device.updateField(
      WbMqttMessage(topic: topic, payload: message.payload),
    );
    if (route.isInput) {
      route.device.execute();
    }
  }

  TopicRoute? _resolveGenericTopic(String topic) {
    for (final entry in _genericTopics.entries) {
      if (entry.value.hasMatch(topic)) {
        return _routes[entry.key];
      }
    }
    return null;
  }

  Map<String, RegExp> _makeGenericTopick() {
    return Map.fromEntries(
      topics
          .where((e) => e.contains('+') || e.endsWith('#'))
          .map((e) => (e.replaceAll('+', '.+').replaceFirst('#', '.*'), e))
          .map((e) => MapEntry(e.$2, RegExp(e.$1))),
    );
  }
}
