import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/services/database_service.dart';

part 'report_cubit.freezed.dart';

enum ReportType { student, weekly, monthly, highestMarks, collection, attendanceDate }

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
              headers: ['الطالب', 'التسلسل', 'الامتحان', 'الدرجة', 'الدرجة النهائية', 'النسبة'],
              data: results.map((r) {
                final score = (r['score'] as num).toDouble();
                final fullMark = (r['full_mark'] as num).toDouble();
                final pct = fullMark > 0 ? (score / fullMark * 100).toStringAsFixed(1) : '0';
                return [
                  r['student_name'].toString(),
                  r['serial_number'].toString(),
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
        SELECT a.date, a.status, s.name as student_name, s.serial_number, g.name as group_name
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
                headers: ['التاريخ', 'الطالب', 'التسلسل', 'المجموعة', 'الحالة'],
                data: results.map((r) {
                  return [
                    r['date'].toString(),
                    r['student_name'].toString(),
                    r['serial_number'].toString(),
                    r['group_name']?.toString() ?? 'غير متوفر',
                    r['status'].toString(),
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
                .map((a) => [
                      a['date'].toString(),
                      a['status'].toString(),
                      a['notes'].toString(),
                    ])
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
                total.toStringAsFixed(2),
                paid.toStringAsFixed(2),
                (total - paid).toStringAsFixed(2),
              ];
            }).toList(),
          ),
      ],
    );
  }

  void resetReport() {
    emit(const ReportState());
  }
}
