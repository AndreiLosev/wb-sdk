import 'package:wb_sdk/wb_sdk.dart';

class DevelopModeControl extends PartOfIDevice {
  static String name = 'dev_mode';

  final bool hidden;

  new({this.hidden = false});

  @override
  Set<String> addInputs() {
    return {'$name/on', '+/meta'};
  }

  @override
  Map<String, ControlMeta> addMeta() {
    return {
      name: ControlMeta(
        type: WbControlType.switch_,
        title: WbLocalizedTitle(en: 'Development mode', ru: 'Режим разработки'),
        hidden: hidden,
      ),
    };
  }

  bool _update(String name, String payload) {
    return false;
  }

  @override
  UpdateFieldFn? addUpdateFields() => _update;
}
