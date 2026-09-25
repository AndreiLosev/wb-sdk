import 'dart:async';

import 'package:wb_sdk/control/pid_controller_base.dart';

/// PID-регулятор с автоматическим расчётом [_lastCallTime] между вызовами
/// и публикацией выхода в MQTT при длительном интервале.
class PidController extends PidControllerBase {
  PidController({
    required super.kp,
    required super.ki,
    required super.kd,
    required super.mode,
    super.outputMin,
    super.outputMax,
    super.setpoint = 0,
    this.runUpdate,
    this.autoUpdateDelay = const Duration(seconds: 5),
    super.startOffset = 0,
  }) {
    _resetTimer();
  }

  static const double _minDt = 1e-6;

  final Duration autoUpdateDelay;

  final void Function()? runUpdate;

  Timer? _timer;

  int _lastCallTime = 0;

  double calculate({required double processVariable}) {
    final result = update(processVariable: processVariable, dt: _getTimeDiff());
    _resetTimer();

    return result;
  }

  @override
  void reset() {
    super.reset();
    _lastCallTime = 0;
    _timer?.cancel();
    _timer = null;
  }

  double _getTimeDiff() {
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (_lastCallTime == 0) {
      _lastCallTime = now;
      return _minDt;
    }

    final elapsedMs = now - _lastCallTime;
    _lastCallTime = now;
    final elapsed = elapsedMs / 1000;
    return elapsed > 0 ? elapsed : _minDt;
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(autoUpdateDelay, () => runUpdate?.call());
  }
}
