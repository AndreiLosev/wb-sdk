import 'package:wb_annatation/mqtt/wb_mqtt_client.dart';

abstract interface class IDevice {
  WbMqttClient get mqtt;

  void execute();

  void init();

  Set<String> inputs();

  Set<String> outputs();

  void updateField(WbMqttMessage mess);
}
