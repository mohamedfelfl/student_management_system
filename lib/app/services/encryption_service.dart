import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages encryption keys for the SQLite database.
///
/// On first launch, generates a 256-bit AES key and stores it
/// in the platform's secure storage (Keychain on iOS/macOS,
/// EncryptedSharedPreferences on Android, credential manager on Windows).
///
/// Keys created before version 2 were derived from a timestamp. Such a key is
/// "legacy" and gets replaced through [beginKeyRotation] and
/// [completeKeyRotation], with the new key kept as "pending" in between so
/// the database can always be opened, even if the app stops halfway.
class EncryptionService {
  static const _storageKey = 'sms_db_encryption_key';
  static const _pendingKey = 'sms_db_encryption_key_pending';
  static const _versionKey = 'sms_db_key_version';
  static const _currentVersion = '2';

  final FlutterSecureStorage _secureStorage;

  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Returns the database encryption passphrase.
  /// Creates one on first call and persists it securely.
  Future<String> getDatabaseKey() async {
    String? key = await _secureStorage.read(key: _storageKey);
    if (key == null) {
      key = generateKey();
      await _storeCurrentKey(key);
    }
    return key;
  }

  /// Whether the stored key was created by an older version of the app.
  Future<bool> hasLegacyKey() async {
    final String? key = await _secureStorage.read(key: _storageKey);
    final String? version = await _secureStorage.read(key: _versionKey);
    return key != null && version != _currentVersion;
  }

  /// Replaces the stored key with a new random one and returns it.
  ///
  /// Only safe when no database is encrypted with the current key, e.g. when
  /// the database file is still unencrypted.
  Future<String> replaceDatabaseKey() async {
    final String key = generateKey();
    await _storeCurrentKey(key);
    await _secureStorage.delete(key: _pendingKey);
    return key;
  }

  /// First step of re-keying: saves a new key as pending and returns it.
  /// Call [completeKeyRotation] once the database uses it.
  Future<String> beginKeyRotation() async {
    final String key = generateKey();
    await _secureStorage.write(key: _pendingKey, value: key);
    return key;
  }

  /// The key saved by a rotation that has not been completed, if any.
  Future<String?> getPendingKey() => _secureStorage.read(key: _pendingKey);

  /// Second step of re-keying: the database now uses the pending key, so it
  /// becomes the current key.
  Future<void> completeKeyRotation() async {
    final String? pending = await _secureStorage.read(key: _pendingKey);
    if (pending == null) return;
    await _storeCurrentKey(pending);
    await _secureStorage.delete(key: _pendingKey);
  }

  Future<void> _storeCurrentKey(String key) async {
    await _secureStorage.write(key: _storageKey, value: key);
    await _secureStorage.write(key: _versionKey, value: _currentVersion);
  }

  /// Generates a 256-bit key from a cryptographically secure source, written
  /// as 64 hex characters.
  static String generateKey() {
    final Random random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
