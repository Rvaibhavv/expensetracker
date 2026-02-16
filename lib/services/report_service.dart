import 'dart:io';

import 'package:excel/excel.dart';

import '../models/expense.dart';

class ReportService {
  Future<File> exportExpenses({
    required String reportName,
    required List<Expense> expenses,
    required String filePath,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[reportName];

    sheet.appendRow([
      TextCellValue('Date & Time'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Note'),
    ]);

    for (final expense in expenses) {
      sheet.appendRow([
        TextCellValue(expense.createdAt.toIso8601String()),
        TextCellValue(expense.category),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.paymentMode.name.toUpperCase()),
        TextCellValue(expense.note ?? ''),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) throw StateError('Unable to encode Excel file');

    final file = File(filePath);
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }
}
