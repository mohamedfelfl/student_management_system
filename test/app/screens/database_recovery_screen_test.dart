import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/shared/screens/database_recovery_screen.dart';
import 'package:student_management_system/generated/codegen_loader.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      return true;
    });
    await EasyLocalization.ensureInitialized();
  });

  late int startFreshCalls;
  late int retryCalls;

  Future<void> pumpScreen(WidgetTester tester) async {
    startFreshCalls = 0;
    retryCalls = 0;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/translations',
        startLocale: const Locale('ar'),
        fallbackLocale: const Locale('ar'),
        assetLoader: const CodegenLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: DatabaseRecoveryScreen(
              databasePath: r'C:\data\student_management.db',
              onRetry: () async => retryCalls++,
              onStartFresh: () async => startFreshCalls++,
              onExit: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows where the data file is', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining(r'C:\data\student_management.db'), findsOneWidget);
  });

  testWidgets('starting fresh asks for confirmation and can be cancelled',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(DatabaseRecoveryScreen.startFreshButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(DatabaseRecoveryScreen.cancelStartFreshKey));
    await tester.pumpAndSettle();

    expect(startFreshCalls, 0);
  });

  testWidgets('starting fresh runs only after confirming', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(DatabaseRecoveryScreen.startFreshButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DatabaseRecoveryScreen.confirmStartFreshKey));
    await tester.pumpAndSettle();

    expect(startFreshCalls, 1);
  });

  testWidgets('retry calls the retry action', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(DatabaseRecoveryScreen.retryButtonKey));
    await tester.pumpAndSettle();

    expect(retryCalls, 1);
  });
}
