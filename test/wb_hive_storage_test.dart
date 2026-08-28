import 'dart:io';

import 'package:test/test.dart';
import 'package:wb_sdk/mqtt/wb_topic_mapping.dart';
import 'package:wb_sdk/storage/wb_hive_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wb_storage_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getInstanse бросает исключение до open', () {
    expect(
      () => WbHiveStorage.getInstanse(),
      throwsA(isA<Exception>()),
    );
  });

  test('open, put, get и getInstanse', () async {
    final storage = WbHiveStorage(directory: tempDir.path);
    await storage.open();

    storage.put('host', '192.168.1.1');
    expect(storage.get('host', 'localhost'), '192.168.1.1');
    expect(storage.get('missing', 'default'), 'default');
    expect(identical(storage, WbHiveStorage.getInstanse()), isTrue);
  });

  test('WbTopicMapping load/save round-trip', () async {
    final storage = WbHiveStorage(directory: tempDir.path);
    await storage.open();

    final mapping = WbTopicMapping(
      inputs: {'alias/temp/on': 'dev_a/temp/on'},
      outputs: {'dev_a/lamp/on': 'alias/lamp/on'},
    );
    mapping.save(storage);

    final loaded = WbTopicMapping();
    loaded.load(storage);

    expect(loaded.inputs, mapping.inputs);
    expect(loaded.outputs, mapping.outputs);
  });
}
