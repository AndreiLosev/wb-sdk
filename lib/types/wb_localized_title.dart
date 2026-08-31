/// Локализованный заголовок устройства или контрола.
///
/// См. https://github.com/wirenboard/conventions#21-devices-meta-topic
class WbLocalizedTitle {
  const WbLocalizedTitle({this.en, this.ru});

  /// Английский заголовок.
  final String? en;

  /// Русский заголовок.
  final String? ru;

  Map<String, String> toMap() {
    final result = <String, String>{};
    final enVal = en;
    final ruVal = ru;
    if (enVal != null) result['en'] = enVal;
    if (ruVal != null) result['ru'] = ruVal;
    return result;
  }

  static WbLocalizedTitle? fromMap(dynamic map) {
    if (map == null) return null;
    return WbLocalizedTitle(en: map['en'] as String?, ru: map['ru'] as String?);
  }
}
