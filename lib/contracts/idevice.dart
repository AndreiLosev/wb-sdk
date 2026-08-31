import 'package:wb_sdk/wb_sdk.dart';

typedef UpdateFieldFn = bool Function(String control, String payload);

abstract class IDevice {
  final _meta = <String, ControlMeta>{};
  final _inputs = <String>{};
  final _outputs = <String>{};
  final _updateFields = <UpdateFieldFn>[];
  final _parts = <Type, PartOfIDevice>{};
  final _retains = <String, Object?>{};

  String get name;

  WbLocalizedTitle? get title;

  void execute();

  Map<String, ControlMeta> meta() => _meta;

  Set<String> inputs() => _inputs;

  Set<String> outputs() => _outputs;

  Map<String, Object?> retains() => _retains;

  void updateField(WbMqttMessage mess) {
    final prefix = '$name/';
    if (!mess.topic.startsWith(prefix)) {
      return;
    }

    var control = mess.topic.substring(prefix.length);
    if (control.endsWith('/on')) {
      control = control.substring(0, control.length - 3);
    }

    for (final fn in _updateFields) {
      if (fn(control, mess.payload)) {
        return;
      }
    }
  }

  void register<T extends PartOfIDevice>(T part) {
    if (_parts[T] is T) return;
    _parts[T] = part;
    part.setDevice(this);
    _inputs.addAll(part.addInputs());
    _outputs.addAll(part.addOutputs());
    _meta.addAll(part.addMeta());
    final fn = part.addUpdateFields();
    if (fn != null) {
      _updateFields.add(fn);
    }
    _retains.addAll(part.addRetains());
  }

  T part<T extends PartOfIDevice>() => _parts[T] as T;
}

abstract class PartOfIDevice {
  late final IDevice device;

  Set<String> addInputs() => {};
  Set<String> addOutputs() => {};
  Map<String, ControlMeta> addMeta() => {};
  UpdateFieldFn? addUpdateFields() => null;
  Map<String, Object?> addRetains() => {};
  void setDevice(IDevice device) {
    this.device = device;
  }
}
