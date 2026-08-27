import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:wb_annatation/contracts/wb_mqtt_client.dart';

import 'wb_mqtt_topics.dart';
import 'wb_topic_mapping.dart';

/// Реализация [WbMqttClient] на базе `package:mqtt_client`.
class WbClient implements WbMqttClient {
  static WbClient? _instanse;

  WbClient({
    required String host,
    int port = 1883,
    required String clientId,
    this._username,
    this._password,
    this._qos = MqttQos.atLeastOnce,
    this._topicMapping = const WbTopicMapping(),
  }) : _client = MqttServerClient.withPort(host, clientId, port) {
    _client.setProtocolV311();
    _client.keepAlivePeriod = 60;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
  }

  final MqttServerClient _client;
  final String? _username;
  final String? _password;
  final MqttQos _qos;
  final WbTopicMapping _topicMapping;

  final _messagesController = StreamController<WbMqttMessage>.broadcast();
  final _subscribedTopics = <String>{};

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _updatesSubscription;

  static WbClient getInstanse() {
    if (_instanse == null) {
      throw Exception("WbClient must be initialized");
    }

    return _instanse!;
  }

  /// Подключение к MQTT-брокеру.
  Future<void> connect() async {
    final status = await _client.connect(_username, _password);
    if (status?.state != MqttConnectionState.connected) {
      throw StateError(
        'MQTT connection failed: ${status ?? _client.connectionStatus}',
      );
    }

    _updatesSubscription ??= _client.updates!.listen(_onUpdates);

    _instanse ??= this;
  }

  /// Отключение от брокера без закрытия потока сообщений.
  void disconnect() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _client.disconnect();
  }

  /// Отписка от всех топиков, disconnect и закрытие [messages].
  Future<void> dispose() async {
    for (final topic in _subscribedTopics) {
      _client.unsubscribe(WbMqttTopics.toBrokerTopic(topic));
    }
    _subscribedTopics.clear();
    disconnect();
    await _messagesController.close();
  }

  @override
  Stream<WbMqttMessage> get messages => _messagesController.stream;

  @override
  void publish(String topic, String payload, {bool retained = false}) {
    for (final mappedTopic in _topicMapping.expandOutputTopics(topic)) {
      _client.publishMessage(
        WbMqttTopics.toBrokerTopic(mappedTopic),
        _qos,
        makePayload(payload).payload!,
        retain: retained,
      );
    }
  }

  @override
  void subscribe(String topic) {
    _subscribedTopics.add(topic);
    _client.subscribe(WbMqttTopics.toBrokerTopic(topic), _qos);
  }

  @override
  void unsubscribe(String topic) {
    _subscribedTopics.remove(topic);
    _client.unsubscribe(WbMqttTopics.toBrokerTopic(topic));
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage?>> messages) {
    final received = messages.first;
    final message = received.payload;
    if (message is! MqttPublishMessage) {
      return;
    }

    final shortTopic = WbMqttTopics.fromBrokerTopic(received.topic);
    if (shortTopic == null) {
      return;
    }

    final payload = MqttPublishPayload.bytesToStringAsString(
      message.payload.message,
    );

    _messagesController.add(WbMqttMessage(topic: shortTopic, payload: payload));
  }

  MqttClientPayloadBuilder makePayload(String payload) {
    final builder = MqttClientPayloadBuilder();

    for (var b in utf8.encode(payload)) {
      builder.addByte(b);
    }

    return builder;
  }
}
