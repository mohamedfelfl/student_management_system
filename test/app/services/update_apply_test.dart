import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:student_management_system/app/services/update_service.dart';

const String _fullPackageUrl = 'https://example.test/download/full.nupkg';
const String _setupUrl = 'https://example.test/download/Setup.exe';
const String _releasePage = 'https://github.com/o/r/releases/tag/v1.0.6';
const int _pid = 4242;

/// Applying updates: what the service downloads and which processes it
/// starts, using a fake install folder and a fake GitHub.
void main() {
  late Directory root;
  late List<String> requestedUrls;
  late List<List<String>> startedProcesses;
  late List<int> exitCodes;

  http.Client fakeGitHub() => MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            json.encode({
              'tag_name': 'v1.0.6',
              'html_url': _releasePage,
              'body': 'Fixes',
              'assets': [
                {
                  'name': 'StudentManagementSystem-1.0.6-full.nupkg',
                  'browser_download_url': _fullPackageUrl,
                  'size': 4,
                },
                {
                  'name': 'StudentManagementSystem-win-Setup.exe',
                  'browser_download_url': _setupUrl,
                  'size': 4,
                },
              ],
            }),
            200,
          );
        }
        return http.Response.bytes([80, 75, 3, 4], 200);
      });

  /// An app started from `<root>/current` next to `<root>/Update.exe`
  /// (installed with Setup.exe), or from a plain build folder (not installed).
  VelopackUpdateService service({required bool installed}) {
    final Directory exeDir = Directory(
      p.join(root.path, installed ? 'current' : 'build'),
    )..createSync(recursive: true);
    if (installed) File(p.join(root.path, 'Update.exe')).writeAsStringSync('');
    return VelopackUpdateService(
      owner: 'o',
      repo: 'r',
      httpClient: fakeGitHub(),
      executablePath: () => p.join(exeDir.path, 'student_management_system.exe'),
      startDetachedProcess: (exe, args) async =>
          startedProcesses.add([exe, ...args]),
      exitApp: exitCodes.add,
      processId: () => _pid,
    );
  }

  String downloadedPackage() => p.join(
        root.path,
        'packages',
        'StudentManagementSystem-1.0.6-full.nupkg',
      );

  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Elite Series',
      packageName: 'student_management_system',
      version: '1.0.5',
      buildNumber: '6',
      buildSignature: '',
    );
    root = await Directory.systemTemp.createTemp('update_apply_test');
    requestedUrls = [];
    startedProcesses = [];
    exitCodes = [];
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  group('installed copy', () {
    test('"restart now" runs Update.exe after this process exits, then quits',
        () async {
      final updates = service(installed: true);
      final info = (await updates.checkForUpdate())!;
      await updates.downloadUpdate(info).drain<void>();

      await updates.applyUpdateAndRestart();

      expect(requestedUrls, contains(_fullPackageUrl));
      expect(startedProcesses, [
        [
          p.join(root.path, 'Update.exe'),
          '--silent', '--rootDir', root.path,
          'apply', '--waitPid', '$_pid', '-p', downloadedPackage(),
        ],
      ]);
      expect(exitCodes, [0]);
    });

    test('"later" does not start the updater while the app is running',
        () async {
      final updates = service(installed: true);
      final info = (await updates.checkForUpdate())!;
      await updates.downloadUpdate(info).drain<void>();

      await updates.applyUpdateOnExit();

      expect(startedProcesses, isEmpty);
      expect(exitCodes, isEmpty);
    });

    test('after "later", closing the app runs Update.exe once, waiting for it',
        () async {
      final updates = service(installed: true);
      final info = (await updates.checkForUpdate())!;
      await updates.downloadUpdate(info).drain<void>();
      await updates.applyUpdateOnExit();

      await updates.applyPendingUpdateOnExit();
      await updates.applyPendingUpdateOnExit();

      expect(startedProcesses, [
        [
          p.join(root.path, 'Update.exe'),
          '--silent', '--rootDir', root.path,
          'apply', '--norestart', '--waitPid', '$_pid', '-p', downloadedPackage(),
        ],
      ]);
    });

    test('closing the app installs nothing when "later" was not chosen',
        () async {
      final updates = service(installed: true);
      final info = (await updates.checkForUpdate())!;
      await updates.downloadUpdate(info).drain<void>();

      await updates.applyPendingUpdateOnExit();

      expect(startedProcesses, isEmpty);
    });
  });

  group('copy not installed with Setup.exe', () {
    test('reports the update as manual, with the release page', () async {
      final info = (await service(installed: false).checkForUpdate())!;

      expect(info.targetVersion, '1.0.6');
      expect(info.canInstallAutomatically, isFalse);
      expect(info.releasePageUrl, _releasePage);
    });

    test('never downloads or runs Setup.exe, and does not quit', () async {
      final updates = service(installed: false);
      final info = (await updates.checkForUpdate())!;

      await expectLater(updates.downloadUpdate(info), emitsError(anything));
      await expectLater(updates.applyUpdateAndRestart(), throwsA(anything));

      expect(requestedUrls, isNot(contains(_setupUrl)));
      expect(startedProcesses, isEmpty);
      expect(exitCodes, isEmpty);
    });
  });
}
