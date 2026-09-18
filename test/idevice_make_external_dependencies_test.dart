import 'package:test/test.dart';
import 'package:wb_sdk/wb_sdk.dart';

void main() {
  group('IDevice.makeExternalDependencies', () {
    test('по умолчанию только outputs', () {
      final dev = _TestDevice(
        name: 'dev_a',
        outputs: {'temp/on'},
      );

      expect(
        IDevice.makeExternalDependencies([dev]),
        ['dev_a/temp/on'],
      );
    });

    test('объединяет inputs, outputs, dependencies и meta', () {
      final dev = _TestDevice(
        name: 'dev_a',
        inputs: {'in/on'},
        outputs: {'out/on'},
        dependencies: {'sensor/x/on'},
        meta: {
          'temp': ControlMeta(type: WbControlType.value),
        },
      );

      expect(
        IDevice.makeExternalDependencies(
          [dev],
          DependenciesType.values,
        ).toSet(),
        {
          'dev_a/in/on',
          'dev_a/out/on',
          'sensor/x/on',
          'dev_a/meta',
          'dev_a/temp/meta',
        },
      );
    });

    test('wildcard в outputs получает префикс устройства', () {
      final dev = _TestDevice(
        name: 'dev_a',
        outputs: {'+/meta'},
      );

      expect(
        IDevice.makeExternalDependencies([dev]),
        ['dev_a/+/meta'],
      );
    });

    test('несколько устройств — объединение топиков', () {
      final a = _TestDevice(name: 'dev_a', outputs: {'x/on'});
      final b = _TestDevice(name: 'dev_b', outputs: {'y/on'});

      expect(
        IDevice.makeExternalDependencies([a, b]).toSet(),
        {'dev_a/x/on', 'dev_b/y/on'},
      );
    });
  });
}

final class _TestDevice extends IDevice {
  _TestDevice({
    required this.name,
    Set<String>? inputs,
    Set<String>? outputs,
    Set<String>? dependencies,
    Map<String, ControlMeta>? meta,
  }) {
    register(
      _TestDevicePart(
        inputs: inputs ?? const {},
        outputs: outputs ?? const {},
        dependencies: dependencies ?? const {},
        meta: meta ?? const {},
      ),
    );
  }

  @override
  final String name;

  @override
  final WbLocalizedTitle? title = null;

  @override
  void execute() {}
}

final class _TestDevicePart extends PartOfIDevice {
  _TestDevicePart({
    required this.inputs,
    required this.outputs,
    required this.dependencies,
    required this.meta,
  });

  final Set<String> inputs;
  final Set<String> outputs;
  final Set<String> dependencies;
  final Map<String, ControlMeta> meta;

  @override
  Set<String> addInputs() => inputs;

  @override
  Set<String> addOutputs() => outputs;

  @override
  Set<String> addDependencies() => dependencies;

  @override
  Map<String, ControlMeta> addMeta() => meta;
}
