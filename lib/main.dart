import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'app/services/database_service.dart';
import 'app/services/update_service.dart';
import 'generated/codegen_loader.g.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Velopack startup lifecycle hooks
  final veloExitCommands = [
    '--veloapp-obsolete',
    '--veloapp-uninstall',
  ];
  if (veloExitCommands.any((cmd) => args.contains(cmd))) {
    exit(0);
  }

  await EasyLocalization.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(800, 600),
      center: true,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize platform-specific database factory (FFI for desktop)
  DatabaseService.initPlatform();

  // Configure dependency injection
  await configureDependencies();

  // Initialize update service (caches version & prepares hooks)
  try {
    await getIt<UpdateService>().initialize();
  } catch (e) {
    debugPrint('UpdateService initialization failed: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      assetLoader: const CodegenLoader(),
      child: const StudentsManagementApp(),
    ),
  );
}
