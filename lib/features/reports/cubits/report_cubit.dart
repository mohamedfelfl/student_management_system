import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../../../app/services/database_service.dart';

part 'report_cubit.freezed.dart';

enum ReportType { student, weekly, monthly, highestMarks, collection, attendanceDate, dailyPayments, groupPayments, assistant, notesDelivery }

@freezed
abstract class ReportState with _$ReportState {
  const factory ReportState({
    @Default(false) bool isLoading,
    @Default(false) bool isGenerated,
    pw.Document? pdfDocument,
    String? error,
  }) = _ReportState;
}

class ReportCubit extends Cubit<ReportState> {
  final DatabaseService _databaseService;

  ReportCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const ReportState());

  /// Generate a full report for a single student.
  Future<void> generateStudentReport(int studentId) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      // Get student info
      final studentRows = await db.rawQuery('''
        SELECT s.*, g.name as group_name
        FROM students s
        LEFT JOIN groups g ON s.group_id = g.id
        WHERE s.id = ?
      ''', [studentId]);

      if (studentRows.isEmpty) {
        emit(const ReportState(error: 'Student not found'));
        return;
      }

      final student = studentRows.first;

      // Get marks
      final marks = await db.rawQuery('''
        SELECT m.score, e.name as exam_name, e.full_mark, e.date
        FROM marks m
        JOIN exams e ON m.exam_id = e.id
        WHERE m.student_id = ?
        ORDER BY e.date DESC
      ''', [studentId]);

      // Get attendance
      final attendance = await db.rawQuery('''
        SELECT * FROM attendance
        WHERE student_id = ?
        ORDER BY date DESC
      ''', [studentId]);

      // Get payments
      final payments = await db.rawQuery('''
        SELECT * FROM payments
        WHERE student_id = ?
        ORDER BY year DESC, month DESC
      ''', [studentId]);

      // Build PDF
      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير الطالب',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            _buildStudentInfoSection(student),
            pw.SizedBox(height: 20),
            _buildMarksSection(marks),
            pw.SizedBox(height: 20),
            _buildAttendanceSection(attendance),
            pw.SizedBox(height: 20),
            _buildPaymentSection(payments),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  /// Generate a report for payments made on a specific day.
  Future<void> generateDailyPaymentReport(DateTime date) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      final String dateStr = date.toIso8601String().split('T').first;

      final results = await db.rawQuery('''
        SELECT p.*, s.name as student_name, s.serial_number
        FROM payments p
        JOIN students s ON p.student_id = s.id
        WHERE p.paid_date LIKE ?
        ORDER BY s.name ASC
      ''', ['$dateStr%']);

      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('تقرير المدفوعات اليومية',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                   pw.Text(dateStr, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            if (results.isEmpty)
              pw.Center(child: pw.Text('لا توجد مدفوعات في هذا اليوم', style: const pw.TextStyle(fontSize: 18)))
            else ...[
              pw.TableHelper.fromTextArray(
                headers: ['التسلسل', 'الطالب', 'الشهر/السنة', 'المبلغ المدفوع', 'الوقت'],
                data: results.map((r) {
                   final paidDate = DateTime.parse(r['paid_date'].toString());
                   final timeStr = DateFormat('HH:mm').format(paidDate);
                   return [
                      r['serial_number'].toString(),
                      r['student_name'].toString(),
                      '${r['month']}/${r['year']}',
                      '${LocaleKeys.currency_symbol.tr()} ${(r['paid_amount'] as num).toDouble().toStringAsFixed(2)}',
                     timeStr,
                   ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('الإجمالي: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    '${LocaleKeys.currency_symbol.tr()} ${results.fold(0.0, (sum, r) => sum + (r['paid_amount'] as num).toDouble()).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  /// Generate a report of highest marks filtered by range and date.
  Future<void> generateHighestMarksReport({
    double? minScore,
    double? maxScore,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (minScore != null) {
        conditions.add('m.score >= ?');
        args.add(minScore);
      }
      if (maxScore != null) {
        conditions.add('m.score <= ?');
        args.add(maxScore);
      }
      if (fromDate != null) {
        conditions.add('e.date >= ?');
        args.add(fromDate.toIso8601String().split('T').first);
      }
      if (toDate != null) {
        conditions.add('e.date <= ?');
        args.add(toDate.toIso8601String().split('T').first);
      }

      final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final results = await db.rawQuery('''
        SELECT m.score, s.name as student_name, s.serial_number,
               e.name as exam_name, e.full_mark, e.date
        FROM marks m
        JOIN students s ON m.student_id = s.id
        JOIN exams e ON m.exam_id = e.id
        $whereClause
        ORDER BY m.score DESC
      ''', args);

      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير أعلى الدرجات',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['التسلسل', 'الطالب', 'الامتحان', 'الدرجة', 'الدرجة النهائية', 'النسبة'],
              data: results.map((r) {
                final score = (r['score'] as num).toDouble();
                final fullMark = (r['full_mark'] as num).toDouble();
                final pct = fullMark > 0 ? (score / fullMark * 100).toStringAsFixed(1) : '0';
                return [
                  r['serial_number'].toString(),
                  r['student_name'].toString(),
                  r['exam_name'].toString(),
                  score.toStringAsFixed(1),
                  fullMark.toStringAsFixed(1),
                  '$pct%',
                ];
              }).toList(),
            ),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  /// Generate a report of student attendance filtered by date range.
  Future<void> generateAttendanceReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (fromDate != null) {
        conditions.add('a.date >= ?');
        args.add(fromDate.toIso8601String().split('T').first);
      }
      if (toDate != null) {
        conditions.add('a.date <= ?');
        args.add(toDate.toIso8601String().split('T').first);
      }

      final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final results = await db.rawQuery('''
        SELECT a.date, a.status, a.notes, s.name as student_name, s.serial_number, g.name as group_name
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        LEFT JOIN groups g ON s.group_id = g.id
        $whereClause
        ORDER BY a.date DESC, s.name ASC
      ''', args);

      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير الحضور',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            if (fromDate != null || toDate != null)
              pw.Text('الفترة: ${fromDate?.toIso8601String().split('T').first ?? 'أي'} إلى ${toDate?.toIso8601String().split('T').first ?? 'أي'}',
                  style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            if (results.isEmpty)
              pw.Text('لا توجد سجلات حضور')
            else
            pw.TableHelper.fromTextArray(
                headers: ['التاريخ', 'التسلسل', 'الطالب', 'المجموعة', 'الحالة', 'الملاحظات'],
                data: results.map((r) {
                  final status = r['status']?.toString() ?? '';
                  final notes = r['notes']?.toString() ?? '';
                  final displayStatus = (status == 'attended' || status == 'otherLesson')
                      ? LocaleKeys.present.tr() 
                      : (status == 'missed' ? LocaleKeys.absent.tr() : LocaleKeys.other_lesson.tr());
                  return [
                    r['date'].toString(),
                    r['serial_number'].toString(),
                    r['student_name'].toString(),
                    r['group_name']?.toString() ?? 'غير متوفر',
                    displayStatus,
                    notes,
                  ];
                }).toList(),
              ),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  Future<pw.Document> _createDocument() async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    return pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );
  }

  pw.Widget _buildStudentInfoSection(Map<String, dynamic> student) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('معلومات الطالب',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('الاسم: ${student['name']}'),
        pw.Text('التسلسل: ${student['serial_number']}'),
        pw.Text('المجموعة: ${student['group_name'] ?? 'غير متوفر'}'),
        pw.Text('الهاتف: ${student['phone1']}'),
        pw.Text('المدرسة: ${student['school']}'),
      ],
    );
  }

  pw.Widget _buildMarksSection(List<Map<String, dynamic>> marks) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('نتائج الامتحانات',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (marks.isEmpty)
          pw.Text('لا توجد سجلات امتحانات')
        else
          pw.TableHelper.fromTextArray(
            headers: ['الامتحان', 'الدرجة', 'الدرجة النهائية', 'النسبة', 'التاريخ'],
            data: marks.map((m) {
              final score = (m['score'] as num).toDouble();
              final full = (m['full_mark'] as num).toDouble();
              final pct = full > 0 ? (score / full * 100).toStringAsFixed(1) : '0';
              return [
                m['exam_name'].toString(),
                score.toStringAsFixed(1),
                full.toStringAsFixed(1),
                '$pct%',
                m['date'].toString(),
              ];
            }).toList(),
          ),
      ],
    );
  }

  pw.Widget _buildAttendanceSection(List<Map<String, dynamic>> attendance) {
    final total = attendance.length;
    final attended = attendance.where((a) => a['status'] == 'attended').length;
    final rate = total > 0 ? (attended / total * 100).toStringAsFixed(1) : '0';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('الحضور',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('نسبة الحضور: $rate% ($attended/$total)'),
        pw.SizedBox(height: 4),
        if (attendance.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: ['التاريخ', 'الحالة', 'الملاحظات'],
            data: attendance
                .take(20)
                .map((a) {
                  final status = a['status']?.toString() ?? '';
                  final notes = a['notes']?.toString() ?? '';
                  final displayStatus = (status == 'attended' || status == 'otherLesson')
                      ? LocaleKeys.present.tr() 
                      : (status == 'missed' ? LocaleKeys.absent.tr() : LocaleKeys.other_lesson.tr());
                  return [
                      a['date'].toString(),
                      displayStatus,
                      notes,
                    ];
                })
                .toList(),
          ),
      ],
    );
  }

  pw.Widget _buildPaymentSection(List<Map<String, dynamic>> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('سجل المدفوعات',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (payments.isEmpty)
          pw.Text('لا توجد سجلات مدفوعات')
        else
          pw.TableHelper.fromTextArray(
            headers: ['الشهر/السنة', 'الإجمالي', 'المدفوع', 'المتبقي'],
            data: payments.map((p) {
              final total = (p['total_amount'] as num).toDouble();
              final paid = (p['paid_amount'] as num).toDouble();
              return [
                '${p['month']}/${p['year']}',
                '${LocaleKeys.currency_symbol.tr()} ${total.toStringAsFixed(2)}',
                '${LocaleKeys.currency_symbol.tr()} ${paid.toStringAsFixed(2)}',
                '${LocaleKeys.currency_symbol.tr()} ${(total - paid).toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
      ],
    );
  }

  /// Generate a report for payments made by students in a specific group within a month range.
  Future<void> generateGroupPaymentsReport({
    required int groupId,
    required String groupName,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      
      final int startVal = fromDate.year * 12 + fromDate.month;
      final int endVal = toDate.year * 12 + toDate.month;

      // Ensure startVal <= endVal
      final minVal = startVal <= endVal ? startVal : endVal;
      final maxVal = startVal > endVal ? startVal : endVal;

      final results = await db.rawQuery('''
        SELECT p.*, s.name as student_name, s.serial_number
        FROM payments p
        JOIN students s ON p.student_id = s.id
        WHERE s.group_id = ?
        AND (p.year * 12 + p.month) >= ?
        AND (p.year * 12 + p.month) <= ?
        ORDER BY s.name ASC, p.year ASC, p.month ASC
      ''', [groupId, minVal, maxVal]);

      final pdf = await _createDocument();

      final fromStr = DateFormat('MM/yyyy').format(fromDate);
      final toStr = DateFormat('MM/yyyy').format(toDate);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير مدفوعات المجموعة',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('المجموعة: $groupName', style: const pw.TextStyle(fontSize: 16)),
            pw.Text('الفترة: $fromStr إلى $toStr', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            if (results.isEmpty)
              pw.Text('لا توجد مدفوعات في هذه الفترة')
            else
              pw.TableHelper.fromTextArray(
                headers: ['التسلسل', 'الطالب', 'الشهر/السنة', 'الإجمالي', 'المدفوع', 'المتبقي', 'تاريخ الدفع'],
                data: results.map((r) {
                  final total = (r['total_amount'] as num).toDouble();
                  final paid = (r['paid_amount'] as num).toDouble();
                  final paidDate = r['paid_date'] != null
                      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['paid_date'].toString()))
                      : '';
                  return [
                    r['serial_number'].toString(),
                    r['student_name'].toString(),
                    '${r['month']}/${r['year']}',
                    total.toStringAsFixed(2),
                    paid.toStringAsFixed(2),
                    (total - paid).toStringAsFixed(2),
                    paidDate,
                  ];
                }).toList(),
              ),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  /// Generate a report for an assistant's attendance.
  Future<void> generateAssistantReport(int assistantId) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      final assistants = await db.query(
        'assistants',
        where: 'id = ?',
        whereArgs: <Object?>[assistantId],
      );

      if (assistants.isEmpty) {
        emit(const ReportState(error: 'Assistant not found'));
        return;
      }
      final assistant = assistants.first;

      final attendanceRecords = await db.rawQuery('''
        SELECT * FROM assistant_attendance
        WHERE assistant_id = ?
        ORDER BY date DESC, id DESC
      ''', [assistantId]);

      final pdf = await _createDocument();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير حضور المساعد',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('الاسم: ${assistant['name']}', style: const pw.TextStyle(fontSize: 16)),
            pw.Text('رقم التسلسل: ${assistant['serial_number']}', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('رقم الهاتف: ${assistant['phone']}', style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            if (attendanceRecords.isEmpty)
              pw.Text('لا توجد سجلات حضور لهذا المساعد')
            else
              pw.TableHelper.fromTextArray(
                headers: ['التاريخ', 'النوع'],
                data: attendanceRecords.map((r) {
                  return [
                    r['date'].toString(),
                    r['type'] == 'in' ? 'حضور' : 'انصراف',
                  ];
                }).toList(),
              ),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  /// Generate a notes delivery report for a student or group.
  Future<void> generateNotesDeliveryReport({
    int? studentId,
    int? groupId,
    String? groupName,
  }) async {
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      // Get all notes
      final notes = await db.query('notes', orderBy: 'id ASC');
      if (notes.isEmpty) {
        emit(const ReportState(error: 'No notes found'));
        return;
      }

      // Get students
      String studentQuery = '''
        SELECT s.*, g.name as group_name
        FROM students s
        LEFT JOIN groups g ON s.group_id = g.id
      ''';
      List<Object?> studentArgs = [];

      if (studentId != null) {
        studentQuery += ' WHERE s.id = ?';
        studentArgs = [studentId];
      } else if (groupId != null) {
        studentQuery += ' WHERE s.group_id = ?';
        studentArgs = [groupId];
      }
      studentQuery += ' ORDER BY s.serial_number ASC';

      final students = await db.rawQuery(studentQuery, studentArgs);

      if (students.isEmpty) {
        emit(const ReportState(error: 'No students found'));
        return;
      }

      // Get all deliveries for the relevant students
      final studentIds = students.map((s) => s['id'] as int).toList();
      final placeholders = List.filled(studentIds.length, '?').join(',');
      final deliveries = await db.rawQuery(
        'SELECT * FROM student_notes WHERE student_id IN ($placeholders)',
        studentIds,
      );

      // Build a set of (student_id, note_id) for quick lookup
      final deliverySet = <String>{};
      for (final d in deliveries) {
        deliverySet.add('${d['student_id']}_${d['note_id']}');
      }

      // Build the PDF
      final pdf = await _createDocument();

      String title = 'تقرير تسليم المذكرات';
      if (groupName != null) {
        title += ' - $groupName';
      } else if (studentId != null && students.isNotEmpty) {
        title += ' - ${students.first['name']}';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(title,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'م',
                'اسم الطالب',
                ...notes.map((n) => n['name'] as String),
              ],
              data: students.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final sId = s['id'] as int;
                return [
                  '${idx + 1}',
                  s['name'].toString(),
                  ...notes.map((n) {
                    final nId = n['id'] as int;
                    final key = '${sId}_$nId';
                    return deliverySet.contains(key) ? '✓' : '✗';
                  }),
                ];
              }).toList(),
            ),
          ],
        ),
      );

      emit(ReportState(isGenerated: true, pdfDocument: pdf));
    } catch (e) {
      emit(ReportState(error: e.toString()));
    }
  }

  void resetReport() {
    emit(const ReportState());
  }
}
