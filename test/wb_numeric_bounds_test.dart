import 'package:test/test.dart';
import 'package:wb_annatation/wb_annatation.dart';

void main() {
  group('WbNumericBounds', () {
    test('normalizeDouble ограничивает min и max', () {
      expect(
        WbNumericBounds.normalizeDouble(6000, min: 0, max: 5000),
        5000,
      );
      expect(
        WbNumericBounds.normalizeDouble(-5, min: 0, max: 5000),
        0,
      );
    });

    test('normalizeDouble округляет по precision', () {
      expect(
        WbNumericBounds.normalizeDouble(42.56, precision: 0.1),
        42.6,
      );
    });

    test('normalizeDouble убирает артефакты float при precision 0.1', () {
      final value = WbNumericBounds.normalizeDouble(15.698, precision: 0.1);
      expect(value, 15.7);
      expect(value.toString(), '15.7');
    });

    test('normalizeDouble применяет clamp и precision', () {
      expect(
        WbNumericBounds.normalizeDouble(
          6000.56,
          min: 0,
          max: 5000,
          precision: 0.1,
        ),
        5000,
      );
    });

    test('normalizeInt ограничивает и округляет', () {
      expect(
        WbNumericBounds.normalizeInt(120, min: 0, max: 100),
        100,
      );
    });
  });
}
