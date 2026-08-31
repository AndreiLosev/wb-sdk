import 'dart:convert';

import 'package:wb_sdk/types/wb_control_type.dart';

import 'types/wb_localized_title.dart';

/// Сериализация meta JSON для Wiren Board MQTT.
abstract final class WbMetaJson {
  /// Meta устройства (`{device}/meta`).
  static String device(WbLocalizedTitle? title) {
    return jsonEncode({'driver': 'vktmotage', 'title': _titleMap(title)});
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

class ControlMeta {
  WbControlType type;
  WbLocalizedTitle? title;
  String? units;
  int? min;
  int? max;
  double? precision;
  bool readonly = false;
  bool hidden = false;
  Map<String, WbLocalizedTitle>? enumTitles;
  int? order;
  String? sender;

  new({
    required this.type,
    this.title,
    this.units,
    this.min,
    this.max,
    this.precision,
    this.readonly = false,
    this.hidden = false,
    this.enumTitles,
    this.order,
    this.sender,
  });

  ControlMeta._fromMap(Map<String, dynamic> map)
    : type = WbControlType.fromString(map['type']),
      title = WbLocalizedTitle.fromMap(map['title']),
      units = map['units'] as String?,
      min = map['min'] as int?,
      max = map['max'] as int?,
      precision = map['precision'] as double?,
      readonly = map['readonly'] as bool? ?? false,
      hidden = map['hidden'] as bool? ?? false,
      enumTitles = _parseEnumTitles(map['enumTitles'] as Map<String, dynamic>?),
      order = map['order'] as int?,
      sender = map['sender'] as String?;

  String toJson() => jsonEncode({
    'type': type.mqttValue,
    'title': ?title?.toMap(),
    'units': ?units,
    'min': ?min,
    'max': ?max,
    'precision': ?precision,
    'readonly': readonly,
    'hidden': hidden,
    'enumTitles': ?_serializeEnumTitles(enumTitles!),
    'order': ?order,
    'sender': ?sender,
  });

  factory ControlMeta.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ControlMeta._fromMap(map);
  }

  static Map<String, WbLocalizedTitle>? _parseEnumTitles(
    Map<String, dynamic>? map,
  ) {
    if (map == null) return null;
    final result = <String, WbLocalizedTitle>{};
    for (final entry in map.entries) {
      final title = WbLocalizedTitle.fromMap(entry.value);
      if (title != null) {
        result[entry.key] = title;
      }
    }
    return result.isEmpty ? null : result;
  }

  static Map<String, Map>? _serializeEnumTitles(
    Map<String, WbLocalizedTitle>? titles,
  ) {
    if (titles == null) return null;
    return titles.map((key, value) => MapEntry(key, value.toMap()));
  }
}
