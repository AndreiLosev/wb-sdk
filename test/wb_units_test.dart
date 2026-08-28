import 'package:test/test.dart';
import 'package:wb_sdk/types/wb_units.dart';

void main() {
  test('WbUnits.values содержит все 41 единицу из conventions', () {
    expect(WbUnits.values, hasLength(41));
    expect(WbUnits.values, contains(WbUnits.degreesCelsius));
    expect(WbUnits.values, contains(WbUnits.relativeHumidity));
  });

  test('значения совпадают со строками Wiren Board', () {
    expect(WbUnits.watt, 'W');
    expect(WbUnits.cubicMetersPerHour, 'm^3/h');
    expect(WbUnits.voltAmpereReactive, 'var');
  });
}
