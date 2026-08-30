import 'package:wb_sdk/wb_sdk.dart';

class DevelopModeControl extends PartOfIDevice {
  static String name = 'dev_mode';

  final bool hidden;

  Map<String, Map<String, dynamic>>? _meta;
  Map<String, Map<String, dynamic>>? _devMeta;

  new({this.hidden = false});

  @override
  Set<String> addInputs() {
    return {name};
  }

  @override
  Map<String, Map<String, dynamic>> addMeta() {
    return {
      name: {
        'type': WbControlType.switch_.mqttValue,
        'title': {'en': 'Development mode', 'ru': 'Режим разработки'},
        'order': device.meta().length + 1,
        'readonly': false,
        'hidden': hidden,
      },
    };
  }

  void _publishMeta(Map<String, Map<String, dynamic>> meta) {
    for (final key in meta.keys) {
      wbPublish('${device.name}/$key/meta', WbControlType.meta(meta[key]!));
    }
  }

  void _prepare() {
    _meta ??= device.meta();
    _devMeta ??= Map.fromEntries(
      device.meta().entries.map(
        (e) =>
            MapEntry(e.key, {...e.value, 'readonly': false, 'hidden': false}),
      ),
    );
  }

  bool _update(String name, String payload) {
    if (name != DevelopModeControl.name) return false;
    _prepare();
    if (payload == '1') {
      _publishMeta(_devMeta!);
      return true;
    } else if (payload == '0') {
      _publishMeta(_meta!);
      return true;
    }

    return false;
  }

  @override
  UpdateFieldFn? addUpdateFields() => _update;
}
