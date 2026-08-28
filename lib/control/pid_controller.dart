import 'dart:async';

import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/control/pid_controller_base.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';

/// PID-регулятор с автоматическим расчётом [_lastCallTime] между вызовами
/// и публикацией выхода в MQTT при длительном интервале.
class PidController extends PidControllerBase {
  PidController({
    required super.kp,
    required super.ki,
    required super.kd,
    super.outputMin,
    super.outputMax,
    super.setpoint = 0,
    this.runUpdate,
    this.autoUpdateDelay = const Duration(seconds: 10),
  }) {
    _resetTimer();
    _lastCallTime = DateTime.timestamp().millisecondsSinceEpoch;
  }

  static const double _minDt = 1e-6;

  final Duration autoUpdateDelay;

  final WbMqttMessage Function()? runUpdate;

  Timer? _timer;

  late int _lastCallTime;

  double calculate({required double processVariable, double? setpoint}) {
    final result = update(
      processVariable: processVariable,
      dt: _getTimeDiff(),
      setpoint: setpoint,
    );

    _resetTimer();

    return result;
  }

  @override
  void reset() {
    super.reset();
    _lastCallTime = DateTime.timestamp().millisecondsSinceEpoch;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _lastCallTime = DateTime.timestamp().millisecondsSinceEpoch;
  }

  double _getTimeDiff() {
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    final elapsedMs = now - _lastCallTime;
    _lastCallTime = now;
    final elapsed = elapsedMs / 1000;
    return elapsed > 0 ? elapsed : _minDt;
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(autoUpdateDelay, () {
      if (runUpdate == null) {
        return;
      }
      final WbMqttMessage(:topic, :payload) = runUpdate!();
      wbPublish(topic, payload, retained: true);
    });
  }
}
