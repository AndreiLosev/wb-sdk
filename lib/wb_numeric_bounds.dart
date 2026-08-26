/// Ограничение и округление числовых значений контролов.
abstract final class WbNumericBounds {
  static double normalizeDouble(
    double value, {
    double? min,
    double? max,
    double? precision,
  }) {
    if (min != null && value < min) {
      value = min;
    }
    if (max != null && value > max) {
      value = max;
    }
    if (precision != null && precision > 0) {
      value = _roundToPrecision(value, precision);
    }
    return value;
  }

  static int normalizeInt(
    int value, {
    double? min,
    double? max,
    double? precision,
  }) {
    return normalizeDouble(
      value.toDouble(),
      min: min,
      max: max,
      precision: precision,
    ).round();
  }

  static double _roundToPrecision(double value, double precision) {
    final scaled = (value / precision).round();
    final rounded = scaled * precision;
    final digits = _fractionDigitsForPrecision(precision);
    return double.parse(rounded.toStringAsFixed(digits));
  }

  static int _fractionDigitsForPrecision(double precision) {
    final parts = precision.toString().split('.');
    if (parts.length < 2) {
      return 0;
    }

    return parts[1].replaceAll(RegExp(r'0+$'), '').length;
  }
}
