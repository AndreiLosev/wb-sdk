import 'package:wb_sdk/contracts/idevice.dart';

enum DependenciesType { inputs, outputs, dependencies, meta }

Iterable<String> makeExternalDependencies(
  Iterable<IDevice> devices, {
  Iterable<DependenciesType> types = const [DependenciesType.outputs],
  Iterable<String> excludeControles = const [],
}) sync* {
  final selected = types is Set<DependenciesType> ? types : types.toSet();
  final seen = <String>{};

  for (final device in devices) {
    if (selected.contains(DependenciesType.inputs)) {
      for (final topic in device.inputs().where(_filter(excludeControles))) {
        final full = '${device.name}/${_replaceEndOn(topic)}';
        if (seen.add(full)) yield full;
      }
    }
    if (selected.contains(DependenciesType.outputs)) {
      for (final topic in device.outputs().where(_filter(excludeControles))) {
        final full = '${device.name}/${_replaceEndOn(topic)}';
        if (seen.add(full)) yield full;
      }
    }
    if (selected.contains(DependenciesType.dependencies)) {
      for (final topic in device.dependencies().where(
        _filter(excludeControles),
      )) {
        final fill = _replaceEndOn(topic);
        if (seen.add(fill)) yield fill;
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

String _replaceEndOn(String topic) {
  if (topic.endsWith('/on')) {
    return topic.substring(0, topic.length - 3);
  }

  return topic;
}

bool Function(String) _filter(Iterable<String> exclude) =>
    (String e) => !e.endsWith('/meta') && !exclude.contains(e);
