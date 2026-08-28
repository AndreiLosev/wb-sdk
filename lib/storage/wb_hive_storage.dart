import 'package:hive_ce/hive_ce.dart';
import 'package:wb_sdk/contracts/wb_storage.dart';

/// Реализация [WbStorage] на базе `package:hive_ce`.
class WbHiveStorage implements WbStorage {
  static WbHiveStorage? _instanse;

  WbHiveStorage({required this._directory, this.boxName = 'wb_storage'});

  final String _directory;
  final String boxName;

  Box? _box;

  static WbStorage getInstanse() {
    if (_instanse == null) {
      throw Exception('WbHiveStorage must be initialized');
    }

    return _instanse!;
  }

  /// Инициализация Hive и открытие box.
  Future<void> open() async {
    Hive.init(_directory);
    _box = await Hive.openBox(boxName);
    _instanse ??= this;
  }

  @override
  void put(String key, Object? value) {
    _requireBox().put(key, value);
  }

  @override
  Object? get(String key, Object? defaultValue) {
    return _requireBox().get(key, defaultValue: defaultValue);
  }

  Box _requireBox() {
    final box = _box;
    if (box == null) {
      throw StateError('WbHiveStorage must be opened before use');
    }

    return box;
  }
}
