import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';
import 'package:wb_sdk/wb_meta_json.dart';

mixin MetaRessiver on PartOfIDevice {
  static String postfix = 'meta';

  static String topic = '+/meta';

  final _allowControls = <String>{};

  final Map<String, ControlMeta> _defaultMeta = {};

  Map<String, ControlMeta> get defaultMeta => _defaultMeta;

  void addAllowControl(String controlName) {
    _allowControls.add(controlName);
  }

  void updateMeta(Map<String, ControlMeta> meta) {
    for (final m in meta.entries) {
      m.value.sender = runtimeType.toString();
      wbPublish(
        '${device.name}/${m.key}/$postfix',
        m.value.toJson(),
      );
    }
  }

  void rxMeta(
    String topic,
    String payload, [
    List<String> skipSenders = const [],
  ]) {
    if (!topic.endsWith(postfix)) {
      return;
    }

    final controlName = topic.replaceFirst('/$postfix', '');

    if (_allowControls.isNotEmpty && !_allowControls.contains(controlName)) {
      return;
    }

    final meta = ControlMeta.fromJson(payload);

    if (skipSenders.contains(meta.sender)) {
      return;
    }
    _defaultMeta[controlName] = meta;
  }
}
