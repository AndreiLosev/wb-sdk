import 'package:meta/meta.dart';
import 'package:wb_annatation/contracts/idevice.dart';
import 'package:wb_annatation/contracts/wb_mqtt_client.dart';
import 'package:wb_annatation/mqtt/wb_client.dart';
import 'package:wb_annatation/mqtt/wb_topic_mapping.dart';
import 'package:wb_annatation/storage/wb_hive_storage.dart';

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
    this.topicMapping = const WbTopicMapping(),
  });

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

  /// Пропускает [WbHiveStorage.open] и [WbClient.connect].
  @visibleForTesting
  WbOrchestratorBuilder.test({
    required WbMqttClient mqtt,
    this.topicMapping = const WbTopicMapping(),
  }) : _testMqtt = mqtt,
      _mqttHost = '',
      _mqttClientId = '',
      _storageDirectory = '',
      mqttPort = 1883,
      mqttUsername = null,
      mqttPassword = null,
      storageBoxName = 'wb_storage';

  /// Открывает storage, подключает MQTT и возвращает готовый [WbOrchestrator].
  Future<WbOrchestrator> build({required List<IDevice> devices}) async {
    if (_built) {
      throw StateError('WbOrchestratorBuilder.build() already called');
    }
    _built = true;

    final mqtt = _testMqtt ?? await _createMqttClient();
    return WbOrchestrator(
      mqtt: mqtt,
      devices: devices,
      topicMapping: topicMapping,
    );
  }

  Future<WbMqttClient> _createMqttClient() async {
    await WbHiveStorage(
      directory: _storageDirectory,
      boxName: storageBoxName,
    ).open();

    final client = WbClient(
      host: _mqttHost,
      port: mqttPort,
      clientId: _mqttClientId,
      username: mqttUsername,
      password: mqttPassword,
      topicMapping: topicMapping,
    );
    await client.connect();
    return WbClient.getInstanse();
  }
}
