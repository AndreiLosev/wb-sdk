import 'package:wb_annatation/contracts/wb_mqtt_client.dart';

abstract interface class IDevice {
  void execute();

  void init();

  Set<String> inputs();

  Set<String> outputs();

  void updateField(WbMqttMessage mess);
}
