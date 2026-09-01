import 'package:wb_sdk/contracts/idevice.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';
import 'package:wb_sdk/wb_meta_json.dart';

mixin MetaRessiver on PartOfIDevice {
  static String postfix = 'meta';

  static String topic = '+/meta';

  final Map<String, ControlMeta> _defaultMeta = {};

  Map<String, ControlMeta> get defaultMeta => _defaultMeta;

  void updateMeta(Map<String, ControlMeta> meta) {
    for (final m in meta.entries) {
      m.value.sender = runtimeType.toString();
      wbPublish('${device.name}/${m.key}/$postfix', m.value.toJson());
    }
  }

  void rxMeta(String topic, String payload, [String? skipSender]) {
    if (!topic.endsWith(postfix)) {
      return;
    }

    final controlName = topic.replaceFirst('/$postfix', '');

    final meta = ControlMeta.fromJson(payload);

    if (skipSender != null && meta.sender == skipSender) {
      return;
    }
    _defaultMeta[controlName] = meta;
  }
}
