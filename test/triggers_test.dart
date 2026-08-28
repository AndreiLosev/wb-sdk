import 'package:test/test.dart';
import 'package:wb_sdk/control/triggers.dart';

void main() {
  group('Rtrig', () {
    test('стабильный false не даёт импульса', () {
      final trig = Rtrig();

      expect(trig.update(false), isFalse);
      expect(trig.update(false), isFalse);
    });

    test('первый вызов с true даёт импульс (холодный старт)', () {
      final trig = Rtrig();

      expect(trig.update(true), isTrue);
    });

    test('стабильный true даёт импульс только на первом вызове', () {
      final trig = Rtrig();

      expect(trig.update(true), isTrue);
      expect(trig.update(true), isFalse);
      expect(trig.update(true), isFalse);
    });

    test('переход false → true даёт один импульс', () {
      final trig = Rtrig();

      trig.update(false);
      expect(trig.update(true), isTrue);
      expect(trig.update(true), isFalse);
    });

    test('несколько циклов — импульс только на переднем фронте', () {
      final trig = Rtrig();
      final pulses = <bool>[];

      for (final clk in [false, true, true, false, false, true, true, false]) {
        pulses.add(trig.update(clk));
      }

      expect(pulses, [false, true, false, false, false, true, false, false]);
    });

    test('reset сбрасывает состояние и снова даёт импульс на true', () {
      final trig = Rtrig();

      trig.update(false);
      trig.update(true);
      trig.reset();

      expect(trig.update(true), isTrue);
    });
  });

  group('Ftrig', () {
    test('стабильный true не даёт импульса', () {
      final trig = Ftrig();

      trig.update(true);
      expect(trig.update(true), isFalse);
      expect(trig.update(true), isFalse);
    });

    test('первый вызов с false даёт импульс (холодный старт)', () {
      final trig = Ftrig();

      expect(trig.update(false), isTrue);
    });

    test('стабильный false даёт импульс только на первом вызове', () {
      final trig = Ftrig();

      expect(trig.update(false), isTrue);
      expect(trig.update(false), isFalse);
      expect(trig.update(false), isFalse);
    });

    test('переход true → false даёт один импульс', () {
      final trig = Ftrig();

      trig.update(true);
      expect(trig.update(false), isTrue);
      expect(trig.update(false), isFalse);
    });

    test('несколько циклов — импульс только на заднем фронте', () {
      final trig = Ftrig();
      final pulses = <bool>[];

      for (final clk in [true, false, false, true, true, false, false, true]) {
        pulses.add(trig.update(clk));
      }

      expect(pulses, [false, true, false, false, false, true, false, false]);
    });

    test('reset сбрасывает состояние', () {
      final trig = Ftrig();

      trig.update(true);
      trig.update(false);
      trig.reset();

      expect(trig.update(false), isTrue);
    });
  });
}
