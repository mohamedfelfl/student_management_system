import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// A database factory whose background isolate loads the real SQLCipher
/// library shipped with `sqlcipher_library_windows`, the same way the app's
/// factory does, but from the pub cache instead of next to the executable.
DatabaseFactory sqlcipherTestFactory() =>
    createDatabaseFactoryFfi(ffiInit: sqlcipherTestIsolateInit);

/// Runs inside the database isolate.
void sqlcipherTestIsolateInit() {
  final String dir = _sqlcipherAssetsDir();
  open.overrideFor(OperatingSystem.windows, () {
    // sqlcipher.dll depends on OpenSSL; load it first so Windows finds it.
    DynamicLibrary.open(p.join(dir, 'libcrypto-1_1-x64.dll'));
    DynamicLibrary.open(p.join(dir, 'libssl-1_1-x64.dll'));
    return DynamicLibrary.open(p.join(dir, 'sqlcipher.dll'));
  });
}

String _sqlcipherAssetsDir() {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final pkg = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((e) => e['name'] == 'sqlcipher_library_windows');
  final Uri root = Uri.parse(pkg['rootUri'] as String);
  final String rootPath = root.hasScheme
      ? root.toFilePath()
      : p.normalize(p.join(Directory.current.path, '.dart_tool', root.path));
  return p.join(rootPath, 'assets');
}

/// Whether [path] is an unencrypted SQLite file (readable by any tool).
bool isPlaintextSqlite(String path) {
  final RandomAccessFile file = File(path).openSync();
  try {
    return String.fromCharCodes(file.readSync(16)).startsWith('SQLite format 3');
  } finally {
    file.closeSync();
  }
}
