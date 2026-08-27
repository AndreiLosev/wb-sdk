import 'package:test/test.dart';
import 'package:wb_annatation/control/pid_controller.dart';
import 'package:wb_annatation/orchestrator/wb_orchestrator.dart';

void main() {
  group('PidController', () {
    late DateTime fakeTime;
    final published = <(String topic, String payload)>[];

    setUp(() {
      fakeTime = DateTime(2026, 1, 1);
      published.clear();
      wbPublish = (String topic, String payload, {bool retained = true}) {
        published.add((topic, payload));
      };
    });

    PidController createPid({
      double kp = 0,
      double ki = 1,
      double kd = 0,
      double setpoint = 10,
      String outputTopic = 'dev/test/output',
    }) {
      return PidController(
        kp: kp,
        ki: ki,
        kd: kd,
        setpoint: setpoint,
        outputTopic: outputTopic,
        now: () => fakeTime,
      );
    }

    test('первый вызов считает PID с dt=0.001 и без D-составляющей', () {
      final pid = createPid(kp: 0, ki: 1, kd: 1);

      final output = pid.update(processVariable: 0);

      expect(output, closeTo(0.01, 1e-9));
      expect(pid.dTerm, 0);
      expect(pid.integral, closeTo(0.01, 1e-9));
    });

    test('автоматически вычисляет dt между вызовами', () {
      final pid = createPid(kp: 0, ki: 1, kd: 0);

      pid.update(processVariable: 0);
      fakeTime = fakeTime.add(const Duration(seconds: 2));

      final output = pid.update(processVariable: 0);

      expect(output, closeTo(20.01, 1e-9));
      expect(pid.integral, closeTo(20.01, 1e-9));
    });

    test('не публикует при dt <= 10 сек', () {
      final pid = createPid(kp: 2, ki: 0, kd: 0, outputTopic: 'dev/test/out');

      pid.update(processVariable: 5);
      fakeTime = fakeTime.add(const Duration(seconds: 5));
      pid.update(processVariable: 5);

      expect(published, isEmpty);
    });

    test('публикует в топик при dt > 10 сек', () {
      final pid = createPid(kp: 2, ki: 0, kd: 0, outputTopic: 'dev/test/out');

      pid.update(processVariable: 5);
      fakeTime = fakeTime.add(const Duration(seconds: 11));

      final output = pid.update(processVariable: 5);

      expect(output, 10);
      expect(published, [('dev/test/out', '10.0')]);
    });

    test('reset сбрасывает время и D-составляющую на первом вызове', () {
      final pid = createPid(kp: 0, ki: 0, kd: 1);

      pid.update(processVariable: 10);
      fakeTime = fakeTime.add(const Duration(seconds: 2));
      pid.update(processVariable: 12);
      expect(pid.dTerm, isNot(0));

      pid.reset();
      final output = pid.update(processVariable: 12);

      expect(output, 0);
      expect(pid.dTerm, 0);
    });
  });
}
