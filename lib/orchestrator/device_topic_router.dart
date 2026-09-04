import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';

class TopicRoute {
  const TopicRoute({required this.device, required this.isInput});

  final IDevice device;
  final bool isInput;
}

class DeviceTopicRouter {
  DeviceTopicRouter._(
    this._routes,
    this._genericTopics,
    this._dependencies,
    this._genericTopicsForDependencies,
  );

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

    final genericTopics = _makeGenericTopick(routes.keys);

    final dependencies = <String, Set<IDevice>>{};

    for (final dev in devices) {
      for (final topic in dev.dependencies()) {
        if (dependencies[topic] == null) {
          dependencies[topic] = {dev};
          continue;
        }

        dependencies[topic]!.add(dev);
      }
    }

    final genericTopicsForDependencies = _makeGenericTopick(dependencies.keys);

    return DeviceTopicRouter._(
      routes,
      genericTopics,
      dependencies,
      genericTopicsForDependencies,
    );
  }

  final Map<String, TopicRoute> _routes;
  final Map<String, RegExp> _genericTopics;
  final Map<String, Set<IDevice>> _dependencies;
  final Map<String, RegExp> _genericTopicsForDependencies;

  Iterable<String> get topics => _routes.keys.followedBy(_dependencies.keys);

  void route(WbMqttMessage message, WbTopicMapping topicMapping) {
    for (final topic in topicMapping.resolveInputTopics(message.topic)) {
      _routeResolved(topic, message.payload);
    }
  }

  void _routeResolved(String topic, String payload) {
    final route = _routes[topic] ?? _resolveGenericTopic(topic);

    if (route == null) {
      return _routeResolvedDep(topic, payload);
    }
    route.device.updateField(WbMqttMessage(topic: topic, payload: payload));
    if (route.isInput) {
      route.device.execute();
    }
  }

  void _routeResolvedDep(String topic, String payload) {
    final devices = _dependencies[topic] ?? _resolveGenericTopicForDep(topic);

    if (devices == null) {
      return;
    }

    for (final dev in devices) {
      dev.execute();
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

  Set<IDevice>? _resolveGenericTopicForDep(String topic) {
    for (final entry in _genericTopicsForDependencies.entries) {
      if (entry.value.hasMatch(topic)) {
        return _dependencies[entry.key];
      }
    }
    return null;
  }

  static Map<String, RegExp> _makeGenericTopick(Iterable<String> topics) {
    return Map.fromEntries(
      topics
          .where((e) => e.contains('+') || e.endsWith('#'))
          .map((e) => (e.replaceAll('+', '.+').replaceFirst('#', '.*'), e))
          .map((e) => MapEntry(e.$2, RegExp(e.$1))),
    );
  }
}
