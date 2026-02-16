class FinancialYear {
  const FinancialYear({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static FinancialYear forDate(DateTime date) {
    final startYear = date.month >= 4 ? date.year : date.year - 1;
    final start = DateTime(startYear, 4, 1);
    final end = DateTime(startYear + 1, 3, 31, 23, 59, 59);
    return FinancialYear(start: start, end: end);
  }

  String get label => '${start.year}-${end.year}';
}
