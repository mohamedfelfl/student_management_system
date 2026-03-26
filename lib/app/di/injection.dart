import 'package:get_it/get_it.dart';

import '../services/database_service.dart';
import '../services/encryption_service.dart';

final getIt = GetIt.instance;

/// Initialize all service dependencies.
Future<void> configureDependencies() async {
  // Encryption
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());

  // Database
  getIt.registerLazySingleton<DatabaseService>(
    () => DatabaseService(encryptionService: getIt<EncryptionService>()),
  );
}
