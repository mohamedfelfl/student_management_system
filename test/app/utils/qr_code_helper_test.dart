import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/utils/qr_code_helper.dart';

void main() {
  group('QrCodeHelper Tests', () {
    test('extracts direct standard serial number (numeric and prefixed)', () {
      expect(QrCodeHelper.extractSerialNumber('10777'), '10777');
      expect(QrCodeHelper.extractSerialNumber('40777'), '40777');
      expect(QrCodeHelper.extractSerialNumber('EM-10777'), 'EM-10777');
      expect(QrCodeHelper.extractSerialNumber('EL-01-00003'), 'EL-01-00003');
      expect(QrCodeHelper.extractSerialNumber('EL-000001'), 'EL-000001');
    });

    test('extracts serial from printed card pipe pattern', () {
      expect(
        QrCodeHelper.extractSerialNumber(
          'SMS|stu_bd02c7b92a2b49da8a|10777',
        ),
        '10777',
      );
      expect(
        QrCodeHelper.extractSerialNumber(
          'ELITE|stu_bd02c7b92a2b49da8a|EL-01-00003',
        ),
        'EL-01-00003',
      );
      expect(
        QrCodeHelper.extractSerialNumber('SMS|40777'),
        '40777',
      );
    });

    test('extracts serial from printed card hyphen pattern', () {
      expect(
        QrCodeHelper.extractSerialNumber(
          'ELITE-stu_bd02c7b92a2b49da8a-EL-01-00003',
        ),
        'EL-01-00003',
      );
    });

    test('handles whitespace and newlines from hardware barcode scanners', () {
      expect(
        QrCodeHelper.extractSerialNumber('  10777  \n\r'),
        '10777',
      );
      expect(
        QrCodeHelper.extractSerialNumber('  EM-10777  \n\r'),
        'EM-10777',
      );
      expect(
        QrCodeHelper.extractSerialNumber(
          '  SMS|stu_bd02c7b92a2b49da8a|10777\r\n',
        ),
        '10777',
      );
    });

    test('normalizes lowercase prefixed inputs to uppercase', () {
      expect(QrCodeHelper.extractSerialNumber('em-10777'), 'EM-10777');
      expect(QrCodeHelper.extractSerialNumber('el-01-00003'), 'EL-01-00003');
    });

    test('handles empty and null inputs safely', () {
      expect(QrCodeHelper.extractSerialNumber(null), '');
      expect(QrCodeHelper.extractSerialNumber(''), '');
      expect(QrCodeHelper.extractSerialNumber('   '), '');
    });

    test('hasCompleteSerial detects completed serial numbers accurately', () {
      // Complete standard format
      expect(QrCodeHelper.hasCompleteSerial('EM-10777'), isTrue);
      expect(QrCodeHelper.hasCompleteSerial('10777'), isTrue);
      expect(QrCodeHelper.hasCompleteSerial('40777'), isTrue);
      expect(QrCodeHelper.hasCompleteSerial('EL-01-00003'), isTrue);

      // Incomplete / partial strings
      expect(QrCodeHelper.hasCompleteSerial('EM-'), isFalse);
      expect(QrCodeHelper.hasCompleteSerial('EL-'), isFalse);
      expect(QrCodeHelper.hasCompleteSerial(''), isFalse);
      expect(QrCodeHelper.hasCompleteSerial(null), isFalse);
    });

    test('extractAllCandidates extracts serial, legacy ids, and segments in priority order', () {
      final candidates = QrCodeHelper.extractAllCandidates(
        'SMS|stu_bd02c7b92a2b49da8a|10777',
      );
      expect(candidates, contains('10777'));
      expect(candidates, contains('stu_bd02c7b92a2b49da8a'));
      expect(candidates.first, equals('10777'));
    });
  });
}
