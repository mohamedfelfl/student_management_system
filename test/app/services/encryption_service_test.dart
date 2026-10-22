import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/services/encryption_service.dart';

import '../../helpers/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage storage;
  late EncryptionService service;

  setUp(() {
    storage = MemorySecureStorage();
    service = EncryptionService(secureStorage: storage);
  });

  test('a new key is 256 bits written as 64 hex characters', () async {
    final key = await service.getDatabaseKey();

    expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('a new key is not derived from the time it was created', () async {
    final before = DateTime.now().microsecondsSinceEpoch;
    final key = await service.getDatabaseKey();
    final after = DateTime.now().microsecondsSinceEpoch;

    // The old scheme: sha256('sms_secure_<microseconds>').
    for (int t = before - 1000; t <= after + 1000; t++) {
      final guess = sha256.convert(utf8.encode('sms_secure_$t')).toString();
      expect(guess == key, isFalse, reason: 'key matches timestamp $t');
    }
  });

  test('two installations get different keys', () async {
    final first = await service.getDatabaseKey();
    final second = await EncryptionService(secureStorage: MemorySecureStorage())
        .getDatabaseKey();

    expect(first, isNot(second));
  });

  test('the key is stored and returned again on the next launch', () async {
    final first = await service.getDatabaseKey();
    final again = await EncryptionService(secureStorage: storage).getDatabaseKey();

    expect(again, first);
  });
}
