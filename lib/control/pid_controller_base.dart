import 'package:wb_annatation/wb_numeric_bounds.dart';

/// Дискретный PID-регулятор с ограничением выхода, anti-windup
/// и производной по измерению (derivative on measurement).
class PidControllerBase {
  PidControllerBase({
    required this.kp,
    required this.ki,
    required this.kd,
    this.outputMin,
    this.outputMax,
    this.setpoint = 0,
  }) {
    if (outputMin != null &&
        outputMax != null &&
        outputMin! > outputMax!) {
      throw ArgumentError.value(
        outputMin,
        'outputMin',
        'outputMin must be less than or equal to outputMax',
      );
    }
  }

  final double kp;
  final double ki;
  final double kd;
  final double? outputMin;
  final double? outputMax;

  double setpoint;

  double _integral = 0;
  double? _lastPv;

  double _pTerm = 0;
  double _iTerm = 0;
  double _dTerm = 0;

  /// Накопленный интеграл ошибки.
  double get integral => _integral;

  /// Текущая пропорциональная составляющая.
  double get pTerm => _pTerm;

  /// Текущая интегральная составляющая.
  double get iTerm => _iTerm;

  /// Текущая дифференциальная составляющая.
  double get dTerm => _dTerm;

  /// Вычисляет управляющий сигнал на текущем шаге.
  ///
  /// [processVariable] — текущее измеренное значение (PV).
  /// [dt] — интервал времени с предыдущего вызова, в секундах.
  /// [setpoint] — опциональная новая уставка; если не задана, используется [setpoint] поля.
  double update({
    required double processVariable,
    required double dt,
    double? setpoint,
  }) {
    if (dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'dt must be greater than 0');
    }

    if (setpoint != null) {
      this.setpoint = setpoint;
    }

    final error = this.setpoint - processVariable;

    _pTerm = kp * error;

    _integral += error * dt;
    _iTerm = ki * _integral;

    if (_lastPv == null) {
      _dTerm = 0;
    } else {
      _dTerm = -kd * (processVariable - _lastPv!) / dt;
    }

    final rawOutput = _pTerm + _iTerm + _dTerm;
    final output = WbNumericBounds.normalizeDouble(
      rawOutput,
      min: outputMin,
      max: outputMax,
    );

    if (rawOutput != output && _isWindup(error, rawOutput, output)) {
      _integral -= error * dt;
      _iTerm = ki * _integral;
    }

    _lastPv = processVariable;

    return output;
  }

  /// Сбрасывает внутреннее состояние регулятора.
  void reset() {
    _integral = 0;
    _lastPv = null;
    _pTerm = 0;
    _iTerm = 0;
    _dTerm = 0;
  }

  bool _isWindup(double error, double rawOutput, double output) {
    if (outputMin != null && output == outputMin && error < 0) {
      return true;
    }
    if (outputMax != null && output == outputMax && error > 0) {
      return true;
    }
    return false;
  }
}
