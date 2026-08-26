import 'dart:io';

import 'package:test/test.dart';
import 'package:wb_annatation/storage/wb_hive_storage.dart';

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

  test('open, pub, get и getInstanse', () async {
    final storage = WbHiveStorage(directory: tempDir.path);
    await storage.open();

    storage.pub('host', '192.168.1.1');
    expect(storage.get('host', 'localhost'), '192.168.1.1');
    expect(storage.get('missing', 'default'), 'default');
    expect(identical(storage, WbHiveStorage.getInstanse()), isTrue);
  });
}
