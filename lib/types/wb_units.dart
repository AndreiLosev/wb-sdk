/// Единицы измерения для поля `units` в метаданных контролов Wiren Board.
///
/// См. https://github.com/wirenboard/conventions#units
abstract final class WbUnits {
  /// mm per hour, precipitation rate (rainfall rate).
  static const mmPerHour = 'mm/h';

  /// meter per second, speed.
  static const mPerSecond = 'm/s';

  /// watt, power.
  static const watt = 'W';

  /// kilowatt hour, power consumption.
  static const kilowattHour = 'kWh';

  /// voltage.
  static const volt = 'V';

  /// voltage (millivolts).
  static const millivolt = 'mV';

  /// cubic meters per hour, flow.
  static const cubicMetersPerHour = 'm^3/h';

  /// cubic meters, volume.
  static const cubicMeters = 'm^3';

  /// giga calories per hour, heat power.
  static const gcalPerHour = 'Gcal/h';

  /// gram per cubic meter, gas concentration.
  static const gramsPerCubicMeter = 'g/m^3';

  /// calories, energy.
  static const calorie = 'cal';

  /// giga calories, energy.
  static const gcal = 'Gcal';

  /// resistance.
  static const ohm = 'Ohm';

  /// resistance (milliohms).
  static const milliohm = 'mOhm';

  /// pressure.
  static const bar = 'bar';

  /// pressure (100Pa).
  static const millibar = 'mbar';

  /// second.
  static const second = 's';

  /// minute.
  static const minute = 'min';

  /// hour.
  static const hour = 'h';

  /// meter.
  static const meter = 'm';

  /// gram.
  static const gram = 'g';

  /// kilo gram.
  static const kilogram = 'kg';

  /// mole, amount of substance.
  static const mole = 'mol';

  /// candela, luminous intensity.
  static const candela = 'cd';

  /// relative humidity.
  static const relativeHumidity = '%, RH';

  /// temperature.
  static const degreesCelsius = 'deg C';

  /// percent.
  static const percent = '%';

  /// parts per million.
  static const ppm = 'ppm';

  /// parts per billion.
  static const ppb = 'ppb';

  /// ampere, current.
  static const ampere = 'A';

  /// milliampere, current.
  static const milliampere = 'mA';

  /// degree, angle.
  static const degree = 'deg';

  /// radian, angle.
  static const radian = 'rad';

  /// illuminance.
  static const lux = 'lx';

  /// sound level.
  static const decibel = 'dB';

  /// hertz, frequency.
  static const hertz = 'Hz';

  /// revolutions per minute.
  static const rpm = 'rpm';

  /// pressure.
  static const pascal = 'Pa';

  /// volt-ampere reactive, reactive power.
  static const voltAmpereReactive = 'var';

  /// volt-ampere, apparent power.
  static const voltAmpere = 'VA';

  /// kilovolt-ampere reactive hour, reactive energy.
  static const kilovoltAmpereReactiveHour = 'kvarh';

  /// Все допустимые значения `units` из conventions.
  static const values = [
    mmPerHour,
    mPerSecond,
    watt,
    kilowattHour,
    volt,
    millivolt,
    cubicMetersPerHour,
    cubicMeters,
    gcalPerHour,
    gramsPerCubicMeter,
    calorie,
    gcal,
    ohm,
    milliohm,
    bar,
    millibar,
    second,
    minute,
    hour,
    meter,
    gram,
    kilogram,
    mole,
    candela,
    relativeHumidity,
    degreesCelsius,
    percent,
    ppm,
    ppb,
    ampere,
    milliampere,
    degree,
    radian,
    lux,
    decibel,
    hertz,
    rpm,
    pascal,
    voltAmpereReactive,
    voltAmpere,
    kilovoltAmpereReactiveHour,
  ];
}
