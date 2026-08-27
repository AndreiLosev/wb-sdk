import 'package:wb_annatation/control/pid_controller_base.dart';
import 'package:wb_annatation/orchestrator/wb_orchestrator.dart';

/// PID-регулятор с автоматическим расчётом [dt] между вызовами
/// и публикацией выхода в MQTT при длительном интервале.
class PidController extends PidControllerBase {
  PidController({
    required super.kp,
    required super.ki,
    required super.kd,
    super.outputMin,
    super.outputMax,
    super.setpoint = 0,
    required this.outputTopic,
    this.publishMinDt = const Duration(seconds: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const double _firstCallDt = 0.001;

  final String outputTopic;
  final Duration publishMinDt;
  final DateTime Function() _now;

  DateTime? _lastUpdateAt;

  /// Вычисляет управляющий сигнал, автоматически определяя [dt]
  /// по времени с предыдущего вызова, если [dt] не передан.
  @override
  double update({
    required double processVariable,
    double? dt,
    double? setpoint,
  }) {
    final currentTime = _now();
    final resolvedDt = dt ??
        (_lastUpdateAt == null
            ? _firstCallDt
            : currentTime.difference(_lastUpdateAt!).inMicroseconds / 1e6);

    if (dt == null) {
      _lastUpdateAt = currentTime;
    }

    final output = super.update(
      processVariable: processVariable,
      dt: resolvedDt,
      setpoint: setpoint,
    );

    if (dt == null && resolvedDt > publishMinDt.inSeconds) {
      wbPublish(outputTopic, output.toString());
    }

    return output;
  }

  @override
  void reset() {
    super.reset();
    _lastUpdateAt = null;
  }
}
