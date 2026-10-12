import 'package:wb_sdk/wb_sdk.dart';

class FakeExternalService implements IExternalService {
  FakeExternalService({
    required String prefix,
    Set<String>? deps,
  }) : _prefix = prefix,
       deps = deps ?? {};

  final String _prefix;

  final Set<String> deps;
  final messages = <WbMqttMessage>[];

  @override
  String get mqttPrefix => _prefix;

  @override
  Set<String> dependencies() => deps;

  @override
  void handleMessage(WbMqttMessage message) {
    messages.add(message);
  }
}

class FakeDevice extends IDevice {
  FakeDevice({
    required this.name,
    Set<String>? inputs,
  }) {
    register(
      FakeDevicePart(inputs: inputs ?? const {}),
    );
  }

  @override
  final String name;

  @override
  final WbLocalizedTitle? title = null;

  int updateFieldCalls = 0;
  int executeCalls = 0;

  @override
  void execute([String? topic]) {
    executeCalls++;
  }

  @override
  void updateField(WbMqttMessage mess) {
    updateFieldCalls++;
  }
}

class FakeDevicePart extends PartOfIDevice {
  FakeDevicePart({required this.inputs});

  final Set<String> inputs;

  @override
  Set<String> addInputs() => inputs;
}

class FakeWbMqttClient implements WbMqttClient {
  final subscribedTopics = <String>[];

  @override
  Stream<WbMqttMessage> get messages => const Stream.empty();

  @override
  void publish(String topic, String payload, {bool retained = false}) {}

  @override
  void subscribe(String topic) {
    subscribedTopics.add(topic);
  }

  @override
  void unsubscribe(String topic) {}
}

class FakeStorage implements WbStorage {
  final _data = <String, Object?>{};

  @override
  Object? get(String key, Object? defaultValue) => _data[key] ?? defaultValue;

  @override
  void put(String key, Object? value) {
    _data[key] = value;
  }
}
