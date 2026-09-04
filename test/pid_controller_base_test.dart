import 'package:test/test.dart';
import 'package:wb_sdk/control/pid_controller_base.dart';

void main() {
  group('PidControllerBase', () {
    test('P-составляющая пропорциональна ошибке', () {
      final pid = PidControllerBase(
        kp: 2,
        ki: 0,
        kd: 0,
        mode: PidMode.heater,
        setpoint: 10,
      );

      final output = pid.update(processVariable: 5, dt: 1);

      expect(output, 10);
      expect(pid.pTerm, 10);
      expect(pid.iTerm, 0);
      expect(pid.dTerm, 0);
    });

    test('I-составляющая накапливается за несколько шагов', () {
      final pid = PidControllerBase(
        kp: 0,
        ki: 1,
        kd: 0,
        mode: PidMode.heater,
        setpoint: 10,
      );

      expect(pid.update(processVariable: 0, dt: 1), 10);
      expect(pid.integral, 10);

      expect(pid.update(processVariable: 0, dt: 1), 20);
      expect(pid.integral, 20);
      expect(pid.iTerm, 20);
    });

    test('D-составляющая реагирует на изменение измерения', () {
      final pid = PidControllerBase(
        kp: 0,
        ki: 0,
        kd: 1,
        mode: PidMode.heater,
        setpoint: 10,
      );

      pid.update(processVariable: 10, dt: 1);
      final output = pid.update(processVariable: 12, dt: 1);

      expect(pid.dTerm, -2);
      expect(output, -2);
    });

    test('смена setpoint не вызывает скачок D-составляющей', () {
      final pid = PidControllerBase(
        kp: 0,
        ki: 0,
        kd: 1,
        mode: PidMode.heater,
        setpoint: 10,
      );

      pid.update(processVariable: 10, dt: 1);
      final output = pid.update(
        processVariable: 10,
        dt: 1,
        setpoint: 30,
      );

      expect(pid.dTerm, 0);
      expect(output, 0);
    });

    test('ограничивает выход по min и max', () {
      final pid = PidControllerBase(
        kp: 10,
        ki: 0,
        kd: 0,
        mode: PidMode.heater,
        setpoint: 100,
        outputMin: 0,
        outputMax: 50,
      );

      expect(pid.update(processVariable: 0, dt: 1), 50);
      expect(pid.update(processVariable: 100, dt: 1), 0);
    });

    test('anti-windup не даёт интегралу расти при насыщении', () {
      final pid = PidControllerBase(
        kp: 0,
        ki: 1,
        kd: 0,
        mode: PidMode.heater,
        setpoint: 100,
        outputMax: 50,
      );

      for (var i = 0; i < 10; i++) {
        pid.update(processVariable: 0, dt: 1);
      }

      expect(pid.integral, 0);
      expect(pid.update(processVariable: 0, dt: 1), 50);
    });

    test('reset сбрасывает внутреннее состояние', () {
      final pid = PidControllerBase(
        kp: 1,
        ki: 0,
        kd: 1,
        mode: PidMode.heater,
        setpoint: 10,
      );

      pid.update(processVariable: 5, dt: 1);
      pid.reset();

      expect(pid.integral, 0);
      expect(pid.pTerm, 0);
      expect(pid.iTerm, 0);
      expect(pid.dTerm, 0);

      final output = pid.update(processVariable: 5, dt: 1);
      expect(output, 5);
      expect(pid.dTerm, 0);
    });

    test('dt <= 0 бросает ArgumentError', () {
      final pid = PidControllerBase(
        kp: 1,
        ki: 0,
        kd: 0,
        mode: PidMode.heater,
      );

      expect(
        () => pid.update(processVariable: 0, dt: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => pid.update(processVariable: 0, dt: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('outputMin > outputMax бросает ArgumentError', () {
      expect(
        () => PidControllerBase(
          kp: 1,
          ki: 0,
          kd: 0,
          mode: PidMode.heater,
          outputMin: 10,
          outputMax: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
