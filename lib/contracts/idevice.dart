import 'package:wb_annatation/wb_annatation.dart';

abstract interface class IDevice {
  String get name;

  WbLocalizedTitle? get title;

  void execute();

  void init();

  Set<String> inputs();

  Set<String> outputs();

  void updateField(WbMqttMessage mess);
}
