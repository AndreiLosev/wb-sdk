import 'package:meta/meta.dart';
import 'package:wb_annatation/contracts/idevice.dart';
import 'package:wb_annatation/contracts/wb_mqtt_client.dart';
import 'package:wb_annatation/mqtt/wb_client.dart';

class _TopicRoute {
  const _TopicRoute({required this.device, required this.isInput});

  final IDevice device;
  final bool isInput;
}

enum _OrchestratorState { idle, prepared, running, stopped }

/// Управляет [IDevice]: подписки, диспетчеризация MQTT, вызов [IDevice.execute].
class WbOrchestrator {
  WbOrchestrator({required this._mqtt, required List<IDevice> devices})
    : _routes = _buildRoutes(devices);

  final WbMqttClient _mqtt;
  final Map<String, _TopicRoute> _routes;

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

    for (final r in _routes.values) {
      r.device.init();
    }

    for (final r in _routes.values) {
      for (final t in r.device.inputs()) {
        _mqtt.subscribe(t);
      }
      for (final t in r.device.outputs()) {
        _mqtt.subscribe(t);
      }
    }
  }

  void _handleMessage(WbMqttMessage message) {
    final route = _routes[message.topic];
    if (route == null) {
      return;
    }

    route.device.updateField(message);
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
}
