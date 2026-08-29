import 'package:wb_sdk/wb_sdk.dart';

typedef UpdateFieldFn = bool Function(String control, String payload);

abstract base class IDevice {
  final _meta = <String, Map<String, dynamic>>{};
  final _inputs = <String>{};
  final _outputs = <String>{};
  final _updateFields = <UpdateFieldFn>[];
  final _parts = <Type, PartOfIDevice>{};
  final _retains = <String, Object?>{};

  String get name;

  WbLocalizedTitle? get title;

  void execute();

  Map<String, Map<String, dynamic>> meta() => _meta;

  Set<String> inputs() => _inputs;

  Set<String> outputs() => _outputs;

  Map<String, Object?> retains() => _retains;

  void updateField(WbMqttMessage mess) {
    final [device, control] = mess.topic.split('/');
    if (device != name) {
      return;
    }

    for (final fn in _updateFields) {
      if (fn(control, mess.payload)) {
        return;
      }
    }
  }

  void register<T extends PartOfIDevice>(T part) {
    _parts[T] = part;
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

abstract base class PartOfIDevice {
  Set<String> addInputs() => {};
  Set<String> addOutputs() => {};
  Map<String, Map<String, dynamic>> addMeta() => {};
  UpdateFieldFn? addUpdateFields() => null;
  Map<String, Object?> addRetains() => {};
}
