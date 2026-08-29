import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';

class IoMappingSync {
  IoMappingSync({
    required this._mqtt,
    required this._topicMapping,
    this._storage,
  });

  final WbMqttClient _mqtt;
  final WbTopicMapping _topicMapping;
  final WbStorage? _storage;

  void handle(WbMqttMessage message) {
    final parsed = WbTopicMapping.parseIoMappingTopic(message.topic);
    if (parsed == null) {
      return;
    }

    final previousInputKey = parsed.isInput ? parsed.key : null;
    final changed = _topicMapping.applyIoMapping(
      isInput: parsed.isInput,
      key: parsed.key,
      value: message.payload,
    );
    if (!changed) {
      return;
    }

    if (parsed.isInput) {
      _syncInputAliasSubscription(previousInputKey, message.payload);
    }

    final storage = _storage;
    if (storage != null) {
      _topicMapping.save(storage);
    }
  }

  void _syncInputAliasSubscription(String? alias, String value) {
    if (value.isEmpty) {
      if (alias != null) {
        _mqtt.unsubscribe(alias);
      }
      return;
    }

    if (alias != null) {
      _mqtt.subscribe(alias);
    }
  }
}
