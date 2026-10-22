import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/services/mock_update_service.dart';
import 'package:student_management_system/features/settings/cubits/update_cubit.dart';
import 'package:student_management_system/features/settings/models/app_update_info.dart';
import 'package:student_management_system/features/settings/widgets/update_dialog.dart';
import 'package:student_management_system/generated/codegen_loader.g.dart';

const String _releasePage = 'https://github.com/o/r/releases/tag/v1.0.6';

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

  Future<void> pumpDialog(WidgetTester tester, AppUpdateInfo info) async {
    final cubit = UpdateCubit(updateService: MockUpdateService());
    addTearDown(cubit.close);
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
            home: Scaffold(
              body: BlocProvider<UpdateCubit>.value(
                value: cubit,
                child: UpdateDialog(info: info),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an installed copy offers to download and install', (tester) async {
    await pumpDialog(
      tester,
      const AppUpdateInfo(currentVersion: '1.0.5', targetVersion: '1.0.6'),
    );

    expect(find.byKey(UpdateDialog.downloadButtonKey), findsOneWidget);
  });

  testWidgets('a copy that cannot update itself points to the release page',
      (tester) async {
    await pumpDialog(
      tester,
      const AppUpdateInfo(
        currentVersion: '1.0.5',
        targetVersion: '1.0.6',
        canInstallAutomatically: false,
        releasePageUrl: _releasePage,
      ),
    );

    expect(find.byKey(UpdateDialog.downloadButtonKey), findsNothing);
    expect(find.textContaining(_releasePage), findsOneWidget);
  });
}
