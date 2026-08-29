import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
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

  /// Открывает storage, подключает MQTT и возвращает готовый [WbOrchestrator].
  Future<WbOrchestrator> build({required List<IDevice> devices}) async {
    if (_built) {
      throw StateError('WbOrchestratorBuilder.build() already called');
    }
    _built = true;

    await WbHiveStorage(
      directory: _storageDirectory,
      boxName: storageBoxName,
    ).open();
    final storage = WbHiveStorage.getInstanse();
    final mqtt = await _createMqttClient();
    return WbOrchestrator.assemble(
      mqtt: mqtt,
      devices: devices,
      defaults: topicMapping,
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
