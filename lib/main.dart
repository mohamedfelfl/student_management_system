import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'app/services/database_service.dart';
import 'app/services/update_service.dart';
import 'app/shared/screens/database_recovery_screen.dart';
import 'app/theme/app_theme.dart';
import 'generated/codegen_loader.g.dart';
import 'generated/locale_keys.g.dart';

void main(List<String> args) async {
  // Velopack startup lifecycle hooks - must exit immediately with code 0
  final veloExitCommands = [
    '--veloapp-install',
    '--veloapp-updated',
    '--veloapp-obsolete',
    '--veloapp-uninstall',
  ];
  if (veloExitCommands.any((cmd) => args.contains(cmd))) {
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();

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

  final String? unreadableDatabasePath = await _findUnreadableDatabase();
  runApp(
    _localized(
      unreadableDatabasePath == null
          ? const StudentsManagementApp()
          : _DatabaseRecoveryApp(databasePath: unreadableDatabasePath),
    ),
  );
}

Widget _localized(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar'),
    assetLoader: const CodegenLoader(),
    child: child,
  );
}

/// Opens the database once before showing the app. Returns the file path when
/// it exists but cannot be unlocked, so the user gets the recovery screen
/// instead of an app that silently runs without their data.
Future<String?> _findUnreadableDatabase() async {
  try {
    await getIt<DatabaseService>().database;
  } on DatabaseUnlockException catch (e) {
    return e.path;
  } catch (e) {
    // Other failures keep the previous behaviour: they surface in the app.
    debugPrint('Database open check failed: $e');
  }
  return null;
}

class _DatabaseRecoveryApp extends StatelessWidget {
  final String databasePath;

  const _DatabaseRecoveryApp({required this.databasePath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: Builder(
        builder: (context) => DatabaseRecoveryScreen(
          databasePath: databasePath,
          onRetry: () async {
            if (await _findUnreadableDatabase() == null) {
              runApp(_localized(const StudentsManagementApp()));
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(LocaleKeys.db_unlock_still_locked.tr())),
              );
            }
          },
          onStartFresh: () async {
            await getIt<DatabaseService>().quarantineDatabaseAndStartFresh();
            runApp(_localized(const StudentsManagementApp()));
          },
          onExit: () => exit(0),
        ),
      ),
    );
  }
}
