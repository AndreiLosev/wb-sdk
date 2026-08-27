import 'package:meta/meta.dart';
import 'package:wb_annatation/contracts/idevice.dart';
import 'package:wb_annatation/contracts/wb_mqtt_client.dart';
import 'package:wb_annatation/mqtt/wb_client.dart';
import 'package:wb_annatation/mqtt/wb_topic_mapping.dart';

late void Function(String topic, String payload, {bool retained}) wbPublish;

class _TopicRoute {
  const _TopicRoute({required this.device, required this.isInput});

  final IDevice device;
  final bool isInput;
}

enum _OrchestratorState { idle, prepared, running, stopped }

/// Управляет [IDevice]: подписки, диспетчеризация MQTT, вызов [IDevice.execute].
class WbOrchestrator {
  WbOrchestrator({
    required this._mqtt,
    required List<IDevice> devices,
    this._topicMapping = const WbTopicMapping(),
  }) : _routes = _buildRoutes(devices) {
    _makeWpPublish();
  }

  final WbMqttClient _mqtt;
  final Map<String, _TopicRoute> _routes;
  final WbTopicMapping _topicMapping;

  _OrchestratorState _state = _OrchestratorState.idle;

  static Map<String, _TopicRoute> _buildRoutes(List<IDevice> devices) {
    final routes = <String, _TopicRoute>{};

    for (final device in devices) {
      for (final topic in device.inputs()) {
        routes[topic] = _TopicRoute(device: device, isInput: true);
      }
      for (final topic in device.outputs()) {
        routes[topic] = _TopicRoute(device: device, isInput: false);
      }
    }

    return routes;
  }

  /// Инициализирует устройства, подписывается на топики и обрабатывает сообщения.
  Future<void> run() async {
    if (_state == _OrchestratorState.running) {
      throw StateError('WbOrchestrator.run() already running');
    }
    if (_state == _OrchestratorState.stopped) {
      throw StateError('WbOrchestrator already stopped');
    }

    _prepare();
    _state = _OrchestratorState.running;

    try {
      await for (final message in _mqtt.messages) {
        if (_state == _OrchestratorState.stopped) {
          break;
        }
        _handleMessage(message);
      }
    } finally {
      if (_state != _OrchestratorState.stopped) {
        _state = _OrchestratorState.prepared;
      }
    }
  }

  /// Останавливает обработку и освобождает MQTT-ресурсы.
  Future<void> stop() async {
    if (_state == _OrchestratorState.stopped) {
      return;
    }

    _state = _OrchestratorState.stopped;

    if (_mqtt is WbClient) {
      await _mqtt.dispose();
    }
  }

  void _prepare() {
    if (_state != _OrchestratorState.idle) {
      return;
    }
    _state = _OrchestratorState.prepared;

    final devices = <IDevice>{};
    for (final route in _routes.values) {
      devices.add(route.device);
    }
    for (final device in devices) {
      device.init();
    }

    for (final topic in _routes.keys) {
      _mqtt.subscribe(topic);
    }
    for (final topic in _topicMapping.inputSubscriptionTopics) {
      _mqtt.subscribe(topic);
    }
  }

  void _handleMessage(WbMqttMessage message) {
    final topic = _topicMapping.resolveInputTopic(message.topic);
    final route = _routes[topic];
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

  @visibleForTesting
  void dispatchMessage(WbMqttMessage message) {
    _handleMessage(message);
  }

  @visibleForTesting
  void prepareForTest() {
    _prepare();
  }

  void _makeWpPublish() {
    wbPublish = (String topic, String payload, {bool retained = true}) {
      for (final mappedTopic in _topicMapping.expandOutputTopics(topic)) {
        _mqtt.publish(mappedTopic, payload, retained: retained);
      }
    };
  }
}
