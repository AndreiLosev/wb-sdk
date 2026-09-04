import 'package:meta/meta.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/iexternal_service.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/mqtt/wb_client.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';
import 'package:wb_sdk/storage/wb_hive_storage.dart';

import 'wb_orchestrator.dart';

/// Создаёт и инициализирует MQTT-клиент и storage, затем собирает [WbOrchestrator].
///
/// Поддерживает внешние MQTT-сервисы через [IExternalService]: при передаче
/// [build] параметра [services] оркестратор подписывается на `{mqttPrefix}#`
/// и [IExternalService.dependencies], а входящие сообщения маршрутизирует
/// в [IExternalService.handleMessage] с топиком без префикса.
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
    @visibleForTesting this.mqttClientFactory,
    @visibleForTesting this.storageFactory,
  }) : topicMapping = topicMapping ?? WbTopicMapping();

  final String _mqttHost;
  final int mqttPort;
  final String _mqttClientId;
  final String? mqttUsername;
  final String? mqttPassword;
  final String _storageDirectory;
  final String storageBoxName;
  final WbTopicMapping topicMapping;

  /// Замена создания MQTT-клиента (только для тестов).
  @visibleForTesting
  final Future<WbMqttClient> Function()? mqttClientFactory;

  /// Замена открытия Hive storage (только для тестов).
  @visibleForTesting
  final Future<WbStorage> Function()? storageFactory;

  bool _built = false;

  /// Открывает storage, подключает MQTT и возвращает готовый [WbOrchestrator].
  ///
  /// [services] — внешние MQTT-сервисы с собственным [IExternalService.mqttPrefix].
  /// Для каждого сервиса оркестратор подписывается на `{mqttPrefix}#` и
  /// [IExternalService.dependencies], а сообщения с соответствующим префиксом
  /// передаёт в [IExternalService.handleMessage] (топик без префикса, payload as-is).
  Future<WbOrchestrator> build({
    required List<IDevice> devices,
    List<IExternalService> services = const [],
  }) async {
    if (_built) {
      throw StateError('WbOrchestratorBuilder.build() already called');
    }
    _built = true;

    final storage = storageFactory != null
        ? await storageFactory!()
        : await _openHiveStorage();
    final mqtt = mqttClientFactory != null
        ? await mqttClientFactory!()
        : await _createMqttClient();
    return WbOrchestrator.assemble(
      mqtt: mqtt,
      devices: devices,
      defaults: topicMapping,
      storage: storage,
      services: services,
    );
  }

  Future<WbStorage> _openHiveStorage() async {
    await WbHiveStorage(
      directory: _storageDirectory,
      boxName: storageBoxName,
    ).open();
    return WbHiveStorage.getInstanse();
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
