/// Абстракция key-value хранилища на диске.
abstract interface class WbStorage {
  /// Сохранить значение по ключу.
  void put(String key, Object? value);

  /// Прочитать значение; если ключа нет — вернуть [defaultValue].
  Object? get(String key, Object? defaultValue);
}
