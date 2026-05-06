import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../../../app/constants/db_queries.dart';
import '../../../app/services/database_service.dart';

part 'report_cubit.freezed.dart';

enum ReportType {
  student,
  weekly,
  monthly,
  highestMarks,
  collection,
  attendanceDate,
  dailyPayments,
  groupPayments,
  assistant,
  notesDelivery,
}

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

  void resetState() {
    emit(const ReportState());
  }

  /// Generate a full report for a single student.
  Future<void> generateStudentReport(int studentId) async {
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      // Get student info
      final studentRows = await db.rawQuery(
        DBQueries.reportStudentInfo,
        [studentId],
      );

      if (studentRows.isEmpty) {
        emit(ReportState(error: LocaleKeys.student_not_found.tr()));
        return;
      }

      final student = studentRows.first;

      // Get marks
      final marks = await db.rawQuery(
        DBQueries.reportStudentMarks,
        [studentId],
      );

      // Get attendance
      final attendance = await db.rawQuery(
        DBQueries.reportStudentAttendance,
        [studentId],
      );

      // Get payments
      final payments = await db.rawQuery(
        DBQueries.reportStudentPayments,
        [studentId],
      );

      // Build PDF
      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                LocaleKeys.student_report.tr(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      final String dateStr = date.toIso8601String().split('T').first;

      final results = await db.rawQuery(
        DBQueries.reportDailyPayments,
        ['$dateStr%'],
      );

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
                  pw.Text(
                    LocaleKeys.daily_payments_report_title.tr(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            if (results.isEmpty)
              pw.Center(
                child: pw.Text(
                  LocaleKeys.no_payments_today.tr(),
                  style: const pw.TextStyle(fontSize: 18),
                ),
              )
            else ...[
              pw.TableHelper.fromTextArray(
                tableDirection: pw.TextDirection.rtl,
                headerDirection: pw.TextDirection.rtl,
                headerAlignment: pw.Alignment.centerRight,
                cellAlignment: pw.Alignment.centerRight,
                headers: [
                  LocaleKeys.serial_number.tr(),
                  LocaleKeys.student.tr(),
                  LocaleKeys.month_year.tr(),
                  LocaleKeys.paid_amount.tr(),
                  LocaleKeys.time.tr(),
                ],
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
                  pw.Text(
                    '${LocaleKeys.total.tr()}: ',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${LocaleKeys.currency_symbol.tr()} ${results.fold(0.0, (sum, r) => sum + (r['paid_amount'] as num).toDouble()).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
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

  Future<void> generateHighestMarksReport({
    int? examId,
    int? groupId,
    int? limit,
    double? minScore,
    double? maxScore,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (examId != null) {
        conditions.add('m.exam_id = ?');
        args.add(examId);
      }
      if (groupId != null) {
        conditions.add('s.group_id = ?');
        args.add(groupId);
      }
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

      final whereClause = conditions.isEmpty
          ? ''
          : 'WHERE ${conditions.join(' AND ')}';

      String query =
          '''
        ${DBQueries.reportHighestMarksBase}
        $whereClause
        ORDER BY m.score DESC
      ''';

      if (limit != null) {
        query += '\n        LIMIT ?';
        args.add(limit);
      }

      final results = await db.rawQuery(query, args);

      final pdf = await _createDocument();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                LocaleKeys.highest_marks_report_title.tr(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              tableDirection: pw.TextDirection.rtl,
              headerDirection: pw.TextDirection.rtl,
              headerAlignment: pw.Alignment.centerRight,
              cellAlignment: pw.Alignment.centerRight,
              headers: [
                LocaleKeys.serial_number.tr(),
                LocaleKeys.student.tr(),
                LocaleKeys.exam.tr(),
                LocaleKeys.score.tr(),
                LocaleKeys.full_mark.tr(),
                LocaleKeys.percentage.tr(),
              ],
              data: results.map((r) {
                final score = (r['score'] as num).toDouble();
                final fullMark = (r['full_mark'] as num).toDouble();
                final pct = fullMark > 0
                    ? (score / fullMark * 100).toStringAsFixed(1)
                    : '0';
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
    if (state.isLoading) return;
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

      final whereClause = conditions.isEmpty
          ? ''
          : 'WHERE ${conditions.join(' AND ')}';

      final results = await db.rawQuery('''
        ${DBQueries.reportAttendanceBase}
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
              child: pw.Text(
                LocaleKeys.attendance_report_title.tr(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            if (fromDate != null || toDate != null)
              pw.Text(
                '${LocaleKeys.period.tr()}: ${fromDate?.toIso8601String().split('T').first ?? LocaleKeys.any.tr()} ${LocaleKeys.to.tr()} ${toDate?.toIso8601String().split('T').first ?? LocaleKeys.any.tr()}',
                style: pw.TextStyle(fontSize: 14),
              ),
            pw.SizedBox(height: 10),
            if (results.isEmpty)
              pw.Text(LocaleKeys.no_attendance_records_found.tr())
            else
              pw.TableHelper.fromTextArray(
                tableDirection: pw.TextDirection.rtl,
                headerDirection: pw.TextDirection.rtl,
                headerAlignment: pw.Alignment.centerRight,
                cellAlignment: pw.Alignment.centerRight,
                headers: [
                  LocaleKeys.date.tr(),
                  LocaleKeys.serial_number.tr(),
                  LocaleKeys.student.tr(),
                  LocaleKeys.group.tr(),
                  LocaleKeys.status.tr(),
                  LocaleKeys.notes.tr(),
                ],
                data: results.map((r) {
                  final status = r['status']?.toString() ?? '';
                  final notes = r['notes']?.toString() ?? '';
                  final displayStatus =
                      (status == 'attended' || status == 'otherLesson')
                      ? LocaleKeys.present.tr()
                      : (status == 'missed'
                            ? LocaleKeys.absent.tr()
                            : LocaleKeys.other_lesson.tr());
                  return [
                    r['date'].toString(),
                    r['serial_number'].toString(),
                    r['student_name'].toString(),
                    r['group_name']?.toString() ?? LocaleKeys.na.tr(),
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
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );
  }

  pw.Widget _buildStudentInfoSection(Map<String, dynamic> student) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LocaleKeys.student_info.tr(),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('${LocaleKeys.name.tr()}: ${student['name']}'),
        pw.Text('${LocaleKeys.serial_number.tr()}: ${student['serial_number']}'),
        pw.Text('${LocaleKeys.group.tr()}: ${student['group_name'] ?? LocaleKeys.na.tr()}'),
        pw.Text('${LocaleKeys.phone.tr()}: ${student['phone1']}'),
        pw.Text('${LocaleKeys.school.tr()}: ${student['school']}'),
      ],
    );
  }

  pw.Widget _buildMarksSection(List<Map<String, dynamic>> marks) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LocaleKeys.exam_results.tr(),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (marks.isEmpty)
          pw.Text(LocaleKeys.no_exam_records.tr())
        else
          pw.TableHelper.fromTextArray(
            tableDirection: pw.TextDirection.rtl,
            headerDirection: pw.TextDirection.rtl,
            headerAlignment: pw.Alignment.centerRight,
            cellAlignment: pw.Alignment.centerRight,
            headers: [
              LocaleKeys.exam.tr(),
              LocaleKeys.score.tr(),
              LocaleKeys.full_mark.tr(),
              LocaleKeys.percentage.tr(),
              LocaleKeys.date.tr(),
            ],
            data: marks.map((m) {
              final score = (m['score'] as num).toDouble();
              final full = (m['full_mark'] as num).toDouble();
              final pct = full > 0
                  ? (score / full * 100).toStringAsFixed(1)
                  : '0';
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
        pw.Text(
          LocaleKeys.attendance.tr(),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('${LocaleKeys.attendance_rate_label.tr()}: $rate% ($attended/$total)'),
        pw.SizedBox(height: 4),
        if (attendance.isNotEmpty)
          pw.TableHelper.fromTextArray(
            tableDirection: pw.TextDirection.rtl,
            headerDirection: pw.TextDirection.rtl,
            headerAlignment: pw.Alignment.centerRight,
            cellAlignment: pw.Alignment.centerRight,
            headers: [LocaleKeys.date.tr(), LocaleKeys.status.tr(), LocaleKeys.notes.tr()],
            data: attendance.take(20).map((a) {
              final status = a['status']?.toString() ?? '';
              final notes = a['notes']?.toString() ?? '';
              final displayStatus =
                  (status == 'attended' || status == 'otherLesson')
                  ? LocaleKeys.present.tr()
                  : (status == 'missed'
                        ? LocaleKeys.absent.tr()
                        : LocaleKeys.other_lesson.tr());
              return [a['date'].toString(), displayStatus, notes];
            }).toList(),
          ),
      ],
    );
  }

  pw.Widget _buildPaymentSection(List<Map<String, dynamic>> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LocaleKeys.payment_history.tr(),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (payments.isEmpty)
          pw.Text(LocaleKeys.no_payment_records.tr())
        else
          pw.TableHelper.fromTextArray(
            tableDirection: pw.TextDirection.rtl,
            headerDirection: pw.TextDirection.rtl,
            headerAlignment: pw.Alignment.centerRight,
            cellAlignment: pw.Alignment.centerRight,
            headers: [LocaleKeys.month_year.tr(), LocaleKeys.total.tr(), LocaleKeys.paid.tr(), LocaleKeys.remaining.tr()],
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
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      final int startVal = fromDate.year * 12 + fromDate.month;
      final int endVal = toDate.year * 12 + toDate.month;

      // Ensure startVal <= endVal
      final minVal = startVal <= endVal ? startVal : endVal;
      final maxVal = startVal > endVal ? startVal : endVal;

      final results = await db.rawQuery(
        DBQueries.reportGroupPayments,
        [groupId, minVal, maxVal],
      );

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
              child: pw.Text(
                LocaleKeys.group_payments_report_title.tr(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${LocaleKeys.group.tr()}: $groupName',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              '${LocaleKeys.period.tr()}: $fromStr ${LocaleKeys.to.tr()} $toStr',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            if (results.isEmpty)
              pw.Text(LocaleKeys.no_payments_period.tr())
            else
              pw.TableHelper.fromTextArray(
                tableDirection: pw.TextDirection.rtl,
                headerDirection: pw.TextDirection.rtl,
                headerAlignment: pw.Alignment.centerRight,
                cellAlignment: pw.Alignment.centerRight,
                headers: [
                  LocaleKeys.serial_number.tr(),
                  LocaleKeys.student.tr(),
                  LocaleKeys.month_year.tr(),
                  LocaleKeys.total.tr(),
                  LocaleKeys.paid.tr(),
                  LocaleKeys.remaining.tr(),
                  LocaleKeys.payment_date.tr(),
                ],
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
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      final assistants = await db.query(
        DBQueries.tableAssistants,
        where: 'id = ?',
        whereArgs: <Object?>[assistantId],
      );

      if (assistants.isEmpty) {
        emit(ReportState(error: LocaleKeys.assistant_not_found.tr()));
        return;
      }
      final assistant = assistants.first;

      final attendanceRecords = await db.rawQuery(
        DBQueries.reportAssistantAttendance,
        [assistantId],
      );

      final pdf = await _createDocument();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                LocaleKeys.assistant_attendance_report_title.tr(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${LocaleKeys.name.tr()}: ${assistant['name']}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              '${LocaleKeys.serial_number.tr()}: ${assistant['serial_number']}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              '${LocaleKeys.phone_number.tr()}: ${assistant['phone']}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            if (attendanceRecords.isEmpty)
              pw.Text(LocaleKeys.no_assistant_attendance.tr())
            else
              pw.TableHelper.fromTextArray(
                tableDirection: pw.TextDirection.rtl,
                headerDirection: pw.TextDirection.rtl,
                headerAlignment: pw.Alignment.centerRight,
                cellAlignment: pw.Alignment.centerRight,
                headers: [LocaleKeys.date.tr(), LocaleKeys.type.tr()],
                data: attendanceRecords.map((r) {
                  return [
                    r['date'].toString(),
                    r['type'] == 'in' ? LocaleKeys.check_in.tr() : LocaleKeys.check_out.tr(),
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
    int? noteId,
  }) async {
    if (state.isLoading) return;
    emit(const ReportState(isLoading: true));
    try {
      final db = await _databaseService.database;

      // Get notes
      final notes = await db.query(
        DBQueries.tableNotes,
        orderBy: 'id ASC',
        where: noteId != null ? 'id = ?' : null,
        whereArgs: noteId != null ? [noteId] : null,
      );
      
      if (notes.isEmpty) {
        emit(ReportState(error: LocaleKeys.no_notes_found.tr()));
        return;
      }

      // Get students
      String studentQuery = DBQueries.reportNotesDeliveryStudentBase;
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
        emit(ReportState(error: LocaleKeys.no_students_found.tr()));
        return;
      }

      // Get all deliveries for the relevant students
      final studentIds = students.map((s) => s['id'] as int).toList();
      final placeholders = List.filled(studentIds.length, '?').join(',');
      final deliveries = await db.rawQuery(
        'SELECT * FROM ${DBQueries.tableStudentNotes} WHERE student_id IN ($placeholders)',
        studentIds,
      );

      // Build a set of (student_id, note_id) for quick lookup
      final deliverySet = <String>{};
      for (final d in deliveries) {
        deliverySet.add('${d['student_id']}_${d['note_id']}');
      }

      // Build the PDF
      final pdf = await _createDocument();

      String title = LocaleKeys.notes_delivery_report_title.tr();
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
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              tableDirection: pw.TextDirection.rtl,
              headerDirection: pw.TextDirection.rtl,
              headerAlignment: pw.Alignment.centerRight,
              cellAlignment: pw.Alignment.centerRight,
              headers: [
                LocaleKeys.serial_number.tr(),
                LocaleKeys.student.tr(),
                ...notes.map((n) => n['name'] as String),
              ],
              data: students.map((s) {
                final sId = s['id'] as int;
                return [
                  s['serial_number'].toString(),
                  s['name'].toString(),
                  ...notes.map((n) {
                    final nId = n['id'] as int;
                    final key = '${sId}_$nId';
                    return deliverySet.contains(key) ? LocaleKeys.yes.tr() : LocaleKeys.no.tr();
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
