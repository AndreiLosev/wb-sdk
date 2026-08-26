import 'dart:convert';

import 'types/wb_localized_title.dart';

/// Сериализация meta JSON для Wiren Board MQTT.
abstract final class WbMetaJson {
  /// Meta устройства (`{device}/meta`).
  static String device(WbLocalizedTitle? title) {
    return jsonEncode({
      'driver': 'vktmotage',
      'title': _titleMap(title),
    });
  }

  static Map<String, String> _titleMap(WbLocalizedTitle? title) {
    final result = <String, String>{};
    final en = title?.en;
    final ru = title?.ru;
    if (en != null) {
      result['en'] = en;
    }
    if (ru != null) {
      result['ru'] = ru;
    }
    return result;
  }
}
