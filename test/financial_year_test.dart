import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/utils/financial_year.dart';

void main() {
  test('Financial year starts from April', () {
    final fy = FinancialYear.forDate(DateTime(2025, 2, 10));
    expect(fy.start, DateTime(2024, 4, 1));
    expect(fy.end.year, 2025);
    expect(fy.end.month, 3);
  });
}
