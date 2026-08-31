import 'package:wb_sdk/contracts/idevice.dart';

enum Mode { auto, manual, local }

class ControlModeControl extends PartOfIDevice {
  static String name = 'control_mode';

  @override
  Set<String> addInputs() => {'$name/on'};
}
