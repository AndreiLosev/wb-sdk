import 'package:wb_sdk/addtionpal_controls/meta_ressiver.dart';
import 'package:wb_sdk/wb_sdk.dart';

class DevelopModeControl extends PartOfIDevice with MetaRessiver {
  static String name = 'dev_mode';
  static String postfix = 'meta';

  final bool hidden;

  new({this.hidden = false});

  @override
  Set<String> addOutputs() {
    return {'$name/on', MetaRessiver.topic};
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

  @override
  bool updateFields(String control, String payload) {
    rxMeta(control, payload, runtimeType.toString());
    if (control != name) {
      return false;
    }
    if (WbValueCodec.decodeBool(payload)) {
      updateMeta(_metaToDev());
      return true;
    }
    updateMeta(defaultMeta);
    return true;
  }

  Map<String, ControlMeta> _metaToDev() {
    final result = <String, ControlMeta>{};

    for (final m in defaultMeta.entries) {
      result[m.key] = m.value.copyWith(
        hidden: false,
        readonly: false,
        sender: runtimeType.toString(),
      );
    }

    return result;
  }
}
