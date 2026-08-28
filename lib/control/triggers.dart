/// Детектор переднего фронта (R_TRIG): импульс на переходе `false → true`.
class Rtrig {
  bool _m = false;

  /// Возвращает `true` ровно на один вызов при переднем фронте [clk].
  bool update(bool clk) {
    final q = clk && !_m;
    _m = clk;
    return q;
  }

  /// Сбрасывает внутреннее состояние.
  void reset() => _m = false;
}

/// Детектор заднего фронта (F_TRIG): импульс на переходе `true → false`.
class Ftrig {
  bool _m = false;

  /// Возвращает `true` ровно на один вызов при заднем фронте [clk].
  bool update(bool clk) {
    final q = !clk && !_m;
    _m = !clk;
    return q;
  }

  /// Сбрасывает внутреннее состояние.
  void reset() => _m = false;
}
