import 'dart:async';

import 'package:wb_sdk/coder.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/debug/wb_debug_log.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';
import 'package:wb_sdk/wb_meta_json.dart';

import 'wb_orchestrator.dart';

class OrchestratorBootstrap {
  void prepare({
    required WbMqttClient mqtt,
    required Map<String, IDevice> devices,
    required WbTopicMapping topicMapping,
    required Iterable<String> routeTopics,
    WbStorage? storage,
    required void Function() runSystem,
  }) {
    _publishDeviceMeta(devices);

    for (final topic in routeTopics) {
      mqtt.subscribe(topic);
    }
    for (final topic in topicMapping.inputSubscriptionTopics) {
      mqtt.subscribe(topic);
    }

    if (storage != null) {
      topicMapping.publishAll(mqtt);
    }
    for (final topic in WbTopicMapping.ioMappingSubscriptionTopics) {
      mqtt.subscribe(topic);
    }
    for (final topic in WbDebugLog.subscriptionTopics(devices.keys)) {
      mqtt.subscribe(topic);
    }

    _restoreRetains(devices, storage);
    runSystem();
    Future.microtask(() {
      for (final device in devices.values) {
        device.execute();
      }
    });
  }

  void _publishDeviceMeta(Map<String, IDevice> devices) {
    for (final device in devices.values) {
      wbPublish('${device.name}/meta', WbMetaJson.device(device.title));
      for (final entry in device.meta().entries) {
        entry.value.sender = runtimeType.toString();
        wbPublish('${device.name}/${entry.key}/meta', entry.value.toJson());
      }
    }
  }

  void _restoreRetains(Map<String, IDevice> devices, WbStorage? storage) {
    if (storage == null) {
      return;
    }

    for (final device in devices.values) {
      for (final entry in device.retains().entries) {
        final controlMeta = device.meta()[entry.key];
        if (controlMeta == null) {
          throw StateError(
            'Retain field "${entry.key}" has no meta on device "${device.name}"',
          );
        }

        final type = controlMeta.type;
        final value = storage.get('${device.name}.${entry.key}', entry.value);
        final payload = WbValueCodec.encode(value, type);
        device.updateField(
          WbMqttMessage(
            topic: '${device.name}/${entry.key}/on',
            payload: payload,
          ),
        );
      }
    }
  }
}
