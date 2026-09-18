import 'package:wb_sdk/contracts/idevice.dart';

enum DependenciesType { inputs, outputs, dependencies, meta }

Iterable<String> makeExternalDependencies(
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
