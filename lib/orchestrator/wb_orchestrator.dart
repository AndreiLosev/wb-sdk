import 'package:meta/meta.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/debug/wb_debug_log.dart';
import 'package:wb_sdk/mqtt/wb_client.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';

import 'device_topic_router.dart';
import 'io_mapping_sync.dart';
import 'orchestrator_bootstrap.dart';

late void Function(String topic, String payload) wbPublish;

late T Function<T extends IDevice?>(String devName) getDevice;

enum _OrchestratorState { idle, prepared, running, stopped }

/// Управляет [IDevice]: подписки, диспетчеризация MQTT, вызов [IDevice.execute].
class WbOrchestrator {
  WbOrchestrator({
    required WbMqttClient mqtt,
    required List<IDevice> devices,
    required WbTopicMapping topicMapping,
    WbStorage? storage,
  }) : _mqtt = mqtt,
       _topicMapping = topicMapping,
       _router = DeviceTopicRouter.fromDevices(devices),
       _devices = Map.fromEntries(devices.map((e) => MapEntry(e.name, e))),
       _ioMappingSync = IoMappingSync(
         mqtt: mqtt,
         topicMapping: topicMapping,
         storage: storage,
       ),
       _bootstrap = OrchestratorBootstrap(),
       _debugLog = WbDebugLog(mqtt: mqtt),
       _storage = storage {
    _makeWpPublish();
    _makeWbDebugLog();
    _makeGetDevice();
  }

  /// Собирает [WbOrchestrator] из готовых зависимостей (без I/O).
  static WbOrchestrator assemble({
    required WbMqttClient mqtt,
    required List<IDevice> devices,
    WbTopicMapping? defaults,
    WbStorage? storage,
  }) {
    final mapping = WbTopicMapping(
      inputs: defaults?.inputs ?? {},
      outputs: defaults?.outputs ?? {},
    );
    if (storage != null) {
      mapping.load(storage, defaults: defaults);
    }
    return WbOrchestrator(
      mqtt: mqtt,
      devices: devices,
      topicMapping: mapping,
      storage: storage,
    );
  }

  final WbMqttClient _mqtt;
  final DeviceTopicRouter _router;
  final Map<String, IDevice> _devices;
  final IoMappingSync _ioMappingSync;
  final OrchestratorBootstrap _bootstrap;
  final WbDebugLog _debugLog;
  final WbTopicMapping _topicMapping;
  final WbStorage? _storage;

  _OrchestratorState _state = _OrchestratorState.idle;

  /// Инициализирует устройства, подписывается на топики и обрабатывает сообщения.
  Future<void> run() async {
    if (_state == _OrchestratorState.running) {
      throw StateError('WbOrchestrator.run() already running');
    }
    if (_state == _OrchestratorState.stopped) {
      throw StateError('WbOrchestrator already stopped');
    }

    prepare();

    try {
      await for (final message in _mqtt.messages) {
        switch (_state) {
          case _OrchestratorState.stopped:
            break;
          case _OrchestratorState.prepared:
            if (!message.topic.endsWith('meta')) {
              continue;
            }
          default:
        }

        handleMessage(message);
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

  @visibleForTesting
  void prepare() {
    if (_state != _OrchestratorState.idle) {
      return;
    }
    _state = _OrchestratorState.prepared;

    _bootstrap.prepare(
      mqtt: _mqtt,
      devices: _devices,
      topicMapping: _topicMapping,
      routeTopics: _router.topics,
      storage: _storage,
      runSystem: () {
        _state = _OrchestratorState.running;
      },
    );
  }

  @visibleForTesting
  void handleMessage(WbMqttMessage message) {
    if (message.topic.startsWith('debug/')) {
      _handleDebugMessage(message);
      return;
    }

    if (message.topic.startsWith('io_mapping/')) {
      _ioMappingSync.handle(message);
      return;
    }

    _router.route(message, _topicMapping);
  }

  void _handleDebugMessage(WbMqttMessage message) {
    final parts = message.topic.split('/');
    if (parts.length != 2 || parts[0] != 'debug') {
      return;
    }
    _debugLog.updateFlag(parts[1], message.payload);
  }

  void _makeWpPublish() {
    wbPublish = (String topic, String payload) {
      for (final mappedTopic in _topicMapping.expandOutputTopics(topic)) {
        _mqtt.publish(mappedTopic, payload, retained: true);
      }
    };
  }

  void _makeWbDebugLog() {
    wbDebugLog = _debugLog.log;
  }

  void _makeGetDevice() {
    getDevice = _getDevice;
  }

  T _getDevice<T extends IDevice?>(String devName) => _devices[devName] as T;
}
