import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory stand-in for [FlutterSecureStorage] (no platform channel).
///
/// Only read / write / delete / containsKey are supported, which is all the
/// app's services use.
class MemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final String? key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        final String? value = invocation.namedArguments[#value] as String?;
        if (value == null) {
          values.remove(key);
        } else {
          values[key!] = value;
        }
        return Future<void>.value();
      case #delete:
        values.remove(key);
        return Future<void>.value();
      case #containsKey:
        return Future<bool>.value(values.containsKey(key));
    }
    return super.noSuchMethod(invocation);
  }
}
