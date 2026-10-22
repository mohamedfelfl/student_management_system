import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:student_management_system/features/settings/services/device_binding_service.dart';

void main() {
  group('DeviceBindingService transfer code', () {
    late List<String?> logged;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      logged = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => logged.add(message);
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('checking a wrong code does not log the valid code', () {
      final service = DeviceBindingService();

      final isValid = service.validateTransferCode('0000-0000-0000', 'abc123');

      expect(isValid, isFalse);
      expect(logged, isEmpty);
    });
  });

  group('DeviceBindingService copied-installation check', () {
    late Directory exeDir;
    late DeviceBindingService service;

    setUp(() async {
      exeDir = await Directory.systemTemp.createTemp('sentinel_test');
      service = DeviceBindingService(sentinelDirectory: () => exeDir.path);
    });

    tearDown(() async {
      await exeDir.delete(recursive: true);
    });

    File sentinel() => File(p.join(exeDir.path, '.device_bound'));

    test('no sentinel means the installation was not copied', () async {
      expect(await service.isBoundToAnotherDevice(), isFalse);
    });

    test('a sentinel written on this device does not block setup', () async {
      sentinel().writeAsStringSync(await service.generateFingerprint());

      expect(await service.isBoundToAnotherDevice(), isFalse);
    });

    test('a sentinel from another device blocks setup', () async {
      sentinel().writeAsStringSync('fingerprint-of-another-pc');

      expect(await service.isBoundToAnotherDevice(), isTrue);
    });
  });
}
