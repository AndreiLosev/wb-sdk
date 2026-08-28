import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:wb_sdk/contracts/wb_mqtt_client.dart';
import 'package:wb_sdk/control/pid_controller.dart';
import 'package:wb_sdk/orchestrator/wb_orchestrator.dart';

void main() {
  group('PidController', () {
    final published = <(String topic, String payload)>[];

    setUp(() {
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
      Duration autoUpdateDelay = const Duration(seconds: 10),
      WbMqttMessage Function()? runUpdate,
    }) {
      return PidController(
        kp: kp,
        ki: ki,
        kd: kd,
        setpoint: setpoint,
        autoUpdateDelay: autoUpdateDelay,
        runUpdate:
            runUpdate ??
            () => WbMqttMessage(topic: outputTopic, payload: '10.0'),
      );
    }

    test('первый вызов считает PID с dt=_minDt и без D-составляющей', () {
      final pid = createPid(kp: 0, ki: 1, kd: 1);

      final output = pid.calculate(processVariable: 0);

      expect(output, closeTo(1e-5, 1e-9));
      expect(pid.dTerm, 0);
      expect(pid.integral, closeTo(1e-5, 1e-9));
    });

    test('автоматически вычисляет dt между вызовами', () async {
      final pid = createPid(kp: 0, ki: 1, kd: 0);

      pid.calculate(processVariable: 0);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final output = pid.calculate(processVariable: 0);

      expect(output, closeTo(1.0, 0.05));
      expect(pid.integral, closeTo(1.0, 0.05));
    });

    test('не публикует раньше срабатывания таймера', () {
      fakeAsync((async) {
        final pid = createPid(
          kp: 2,
          ki: 0,
          kd: 0,
          outputTopic: 'dev/test/out',
          autoUpdateDelay: const Duration(seconds: 10),
        );

        pid.calculate(processVariable: 5);
        async.elapse(const Duration(seconds: 5));

        expect(published, isEmpty);
      });
    });

    test('публикует по таймеру бездействия', () {
      fakeAsync((async) {
        final pid = createPid(
          kp: 2,
          ki: 0,
          kd: 0,
          outputTopic: 'dev/test/out',
          autoUpdateDelay: const Duration(seconds: 10),
          runUpdate: () =>
              const WbMqttMessage(topic: 'dev/test/out', payload: '10.0'),
        );

        pid.calculate(processVariable: 5);
        async.elapse(const Duration(seconds: 10));

        expect(published, [('dev/test/out', '10.0')]);
      });
    });

    test('reset сбрасывает время и D-составляющую на первом вызове', () async {
      final pid = createPid(kp: 0, ki: 0, kd: 1);

      pid.calculate(processVariable: 10);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      pid.calculate(processVariable: 12);
      expect(pid.dTerm, isNot(0));

      pid.reset();
      final output = pid.calculate(processVariable: 12);

      expect(output, 0);
      expect(pid.dTerm, 0);
    });

    test('reset отменяет ожидающий таймер публикации', () {
      fakeAsync((async) {
        final pid = createPid(
          kp: 2,
          ki: 0,
          kd: 0,
          outputTopic: 'dev/test/out',
          autoUpdateDelay: const Duration(seconds: 10),
        );

        pid.calculate(processVariable: 5);
        pid.reset();
        async.elapse(const Duration(seconds: 10));

        expect(published, isEmpty);
      });
    });
  });
}
