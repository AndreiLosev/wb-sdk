import 'dart:async';

import 'package:wb_annatation/contracts/wb_mqtt_client.dart';
import 'package:wb_annatation/control/pid_controller_base.dart';
import 'package:wb_annatation/orchestrator/wb_orchestrator.dart';

/// PID-регулятор с автоматическим расчётом [_dt] между вызовами
/// и публикацией выхода в MQTT при длительном интервале.
class PidController extends PidControllerBase {
  PidController({
    required super.kp,
    required super.ki,
    required super.kd,
    super.outputMin,
    super.outputMax,
    super.setpoint = 0,
    this._runUpdate,
    this._autoUpdateDelay = const Duration(seconds: 10),
  }) {
    _resetTimer();
  }

  Timer? timer;

  final Duration _autoUpdateDelay;

  final WbMqttMessage Function()? _runUpdate;

  final _dt = Stopwatch();

  double calculate({required double processVariable, double? setpoint}) {
    final result = update(
      processVariable: processVariable,
      dt: _getTimeDiff(),
      setpoint: setpoint,
    );

    _resetTimer();

    return result;
  }

  double _getTimeDiff() {
    if (!_dt.isRunning) {
      _dt.start();
      return 0.01;
    }

    final res = _dt.elapsed.inSeconds.toDouble();

    _dt.reset();

    return res;
  }

  void _resetTimer() {
    timer?.cancel();
    timer = Timer(_autoUpdateDelay, () {
      if (_runUpdate == null) {
        return;
      }
      final WbMqttMessage(:topic, :payload) = _runUpdate();
      wbPublish(topic, payload, retained: true);
    });
  }
}
