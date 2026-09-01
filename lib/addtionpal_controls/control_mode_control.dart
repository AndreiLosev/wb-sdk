import 'package:wb_sdk/addtionpal_controls/meta_ressiver.dart';
import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';
import 'package:wb_sdk/storage/wb_hive_storage.dart';
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
  Set<String> addInputs() => {'$name/on'};

  @override
  Set<String> addOutputs() {
    return controls.map((e) => MetaRessiver.topic.replaceFirst('+', e)).toSet();
  }

  @override
  Map<String, Object?> addRetains() {
    return {name: Mode.auto.name};
  }

  @override
  bool updateFields(String control, String payload) {
    rxMeta(control, payload, runtimeType.toString());

    if (control != name) return false;
    final resolve = Mode.fromString(payload);

    if (resolve == null) return false;

    print({
      'mode': mode,
      'resolve': resolve,
      'control': control,
      'payload': payload,
    });

    if (resolve != mode) {
      WbHiveStorage.getInstanse().put('${device.name}.$name', mode.name);
    }

    mode = resolve;
    wbPublish('${device.name}/$name', mode.name);

    if (mode == Mode.manual) {
      final newMeta = _metaToManual();
      if (newMeta.isNotEmpty) {
        updateMeta(newMeta);
      }
      return true;
    }
    updateMeta(defaultMeta);
    return true;
  }

  Map<String, ControlMeta> _metaToManual() {
    final result = <String, ControlMeta>{};
    for (final control in controls) {
      final value = defaultMeta[control];
      if (value == null) continue;

      result[control] = value.copyWith(readonly: false, hidden: false);
    }

    return result;
  }

  @override
  Map<String, ControlMeta> addMeta() {
    return {
      name: ControlMeta(
        type: WbControlType.text,
        title: WbLocalizedTitle(en: 'Control mode', ru: 'Режим управления'),
        enumTitles: {
          Mode.auto.name: WbLocalizedTitle(en: Mode.auto.name, ru: 'Авто'),
          Mode.manual.name: WbLocalizedTitle(
            en: Mode.manual.name,
            ru: 'Ручной',
          ),
          Mode.local.name: WbLocalizedTitle(
            en: Mode.local.name,
            ru: 'По месту',
          ),
        },
      ),
    };
  }
}
