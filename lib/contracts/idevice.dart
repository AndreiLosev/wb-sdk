import 'package:wb_sdk/wb_sdk.dart';

typedef UpdateFieldFn = bool Function(String control, String payload);

enum DependenciesType { inputs, outputs, dependencies, meta }

abstract class IDevice {
  final _meta = <String, ControlMeta>{};
  final _inputs = <String>{};
  final _outputs = <String>{};
  final _updateFields = <UpdateFieldFn>[];
  final _parts = <Type, PartOfIDevice>{};
  final _retains = <String, Object?>{};
  final _dependencies = <String>{};

  String get name;

  WbLocalizedTitle? get title;

  void execute();

  Map<String, ControlMeta> meta() => _meta;

  Set<String> inputs() => _inputs;

  Set<String> outputs() => _outputs;

  Map<String, Object?> retains() => _retains;

  Set<String> dependencies() => _dependencies;

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
    _dependencies.addAll(part.addDependencies());

    final oreder = meta().length;
    for (final (i, meta) in part.addMeta().entries.indexed) {
      meta.value.order = (meta.value.order ?? (i + 1)) + oreder;
      _meta[meta.key] = meta.value;
    }

    _updateFields.add(part.updateFields);
    _retains.addAll(part.addRetains());
  }

  T part<T extends PartOfIDevice>() => _parts[T] as T;

  static Iterable<String> makeExternalDependencies(
    Iterable<IDevice> devices, [
    Iterable<DependenciesType> types = const [DependenciesType.outputs],
  ]) sync* {
    final selected = types is Set<DependenciesType> ? types : types.toSet();
    final seen = <String>{};

    for (final device in devices) {
      if (selected.contains(DependenciesType.inputs)) {
        for (final topic in device.inputs()) {
          final full = '${device.name}/$topic';
          if (seen.add(full)) yield full;
        }
      }
      if (selected.contains(DependenciesType.outputs)) {
        for (final topic in device.outputs()) {
          final full = '${device.name}/$topic';
          if (seen.add(full)) yield full;
        }
      }
      if (selected.contains(DependenciesType.dependencies)) {
        for (final topic in device.dependencies()) {
          if (seen.add(topic)) yield topic;
        }
      }
      if (selected.contains(DependenciesType.meta)) {
        final deviceMeta = '${device.name}/meta';
        if (seen.add(deviceMeta)) yield deviceMeta;
        for (final key in device.meta().keys) {
          final controlMeta = '${device.name}/$key/meta';
          if (seen.add(controlMeta)) yield controlMeta;
        }
      }
    }
  }
}

abstract class PartOfIDevice {
  late final IDevice device;

  Set<String> addInputs() => {};
  Set<String> addOutputs() => {};
  Map<String, ControlMeta> addMeta() => {};
  Set<String> addDependencies() => {};
  bool updateFields(String control, String payload) => false;
  Map<String, Object?> addRetains() => {};
  void setDevice(IDevice device) {
    this.device = device;
  }
}
