import 'package:wb_sdk/addtionpal_controls/meta_ressiver.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/types/wb_control_type.dart';
import 'package:wb_sdk/types/wb_localized_title.dart';
import 'package:wb_sdk/wb_meta_json.dart';

enum Mode {
  auto,
  manual,
  local;

  static Mode? fromString(String str) {
    return switch (str) {
      'auto' => Mode.auto,
      'manual' => Mode.manual,
      'local' => Mode.local,
      _ => null,
    };
  }
}

class ControlModeControl extends PartOfIDevice with MetaRessiver {
  static String name = 'control_mode';

  final List<String> controls;

  var mode = Mode.auto;

  new({required this.controls});

  @override
  Set<String> addInputs() => {
    '$name/on',
    ...controls.map((e) => MetaRessiver.topic.replaceFirst('+', e)),
  };

  @override
  Map<String, ControlMeta> addMeta() {
    return {
      name: ControlMeta(
        type: WbControlType.text,
        title: WbLocalizedTitle(en: 'Control mode', ru: 'Режим управления'),
      ),
    };
  }
}
