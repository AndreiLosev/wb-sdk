import 'package:wb_sdk/wb_sdk.dart';

class DevelopModeControl extends PartOfIDevice {
  static String name = 'dev_mode';

  final bool hidden;

  Map<String, ControlMeta>? _meta;
  Map<String, ControlMeta>? _devMeta;

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

  void _publishMeta(Map<String, Map<String, dynamic>> meta) {
    for (final key in meta.keys) {
      wbPublish('${device.name}/$key/meta', WbControlType.meta(meta[key]!));
    }
  }

  void _prepare() {}

  bool _update(String name, String payload) {
    return false;
  }

  @override
  UpdateFieldFn? addUpdateFields() => _update;
}
