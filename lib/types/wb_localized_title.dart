/// Локализованный заголовок устройства или контрола.
///
/// См. https://github.com/wirenboard/conventions#21-devices-meta-topic
class WbLocalizedTitle {
  const WbLocalizedTitle({this.en, this.ru});

  /// Английский заголовок.
  final String? en;

  /// Русский заголовок.
  final String? ru;
}
