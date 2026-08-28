import 'package:meta/meta.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/mqtt/wb_client.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';
import 'package:wb_sdk/storage/wb_hive_storage.dart';

import 'wb_orchestrator.dart';

/// Создаёт и инициализирует MQTT-клиент и storage, затем собирает [WbOrchestrator].
class WbOrchestratorBuilder {
  WbOrchestratorBuilder({
    required this._mqttHost,
    this.mqttPort = 1883,
    required this._mqttClientId,
    this.mqttUsername,
    this.mqttPassword,
    required this._storageDirectory,
    this.storageBoxName = 'wb_storage',
    WbTopicMapping? topicMapping,
  }) : topicMapping = topicMapping ?? WbTopicMapping();

  final String _mqttHost;
  final int mqttPort;
  final String _mqttClientId;
  final String? mqttUsername;
  final String? mqttPassword;
  final String _storageDirectory;
  final String storageBoxName;
  final WbTopicMapping topicMapping;

  bool _built = false;

  WbMqttClient? _testMqtt;
  WbStorage? _testStorage;

  /// Пропускает [WbHiveStorage.open] и [WbClient.connect].
  @visibleForTesting
  WbOrchestratorBuilder.test({
    required WbMqttClient mqtt,
    WbTopicMapping? topicMapping,
    WbStorage? storage,
  }) : _testMqtt = mqtt,
       _testStorage = storage,
       _mqttHost = '',
       _mqttClientId = '',
       _storageDirectory = '',
       mqttPort = 1883,
       mqttUsername = null,
       mqttPassword = null,
       storageBoxName = 'wb_storage',
       topicMapping = topicMapping ?? WbTopicMapping();

  /// Открывает storage, подключает MQTT и возвращает готовый [WbOrchestrator].
  Future<WbOrchestrator> build({required List<IDevice> devices}) async {
    if (_built) {
      throw StateError('WbOrchestratorBuilder.build() already called');
    }
    _built = true;

    WbStorage? storage;
    WbTopicMapping mapping;

    if (_testMqtt != null) {
      storage = _testStorage;
      mapping = WbTopicMapping(
        inputs: topicMapping.inputs,
        outputs: topicMapping.outputs,
      );
      if (storage != null) {
        mapping.load(storage, defaults: topicMapping);
      }
    } else {
      await WbHiveStorage(
        directory: _storageDirectory,
        boxName: storageBoxName,
      ).open();
      storage = WbHiveStorage.getInstanse();
      mapping = WbTopicMapping(
        inputs: topicMapping.inputs,
        outputs: topicMapping.outputs,
      );
      mapping.load(storage, defaults: topicMapping);
    }

    final mqtt = _testMqtt ?? await _createMqttClient();
    return WbOrchestrator(
      mqtt: mqtt,
      devices: devices,
      topicMapping: mapping,
      storage: storage,
    );
  }

  Future<WbMqttClient> _createMqttClient() async {
    final client = WbClient(
      host: _mqttHost,
      port: mqttPort,
      clientId: _mqttClientId,
      username: mqttUsername,
      password: mqttPassword,
    );
    await client.connect();
    return WbClient.getInstanse();
  }
}
