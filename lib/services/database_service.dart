import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'expense_tracker.db'),
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            paymentMode TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> addExpense(Expense expense) async {
    final database = await db;
    await database.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses({DateTime? from, DateTime? to, String? category}) async {
    final database = await db;

    final where = <String>[];
    final args = <Object?>[];

    if (from != null) {
      where.add('createdAt >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('createdAt <= ?');
      args.add(to.toIso8601String());
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }

    final rows = await database.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'createdAt DESC',
    );

    return rows.map(Expense.fromMap).toList();
  }

  Future<double> sumExpenses({required DateTime from, required DateTime to}) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE createdAt >= ? AND createdAt <= ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> categoryTotals({required DateTime from, required DateTime to}) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE createdAt >= ? AND createdAt <= ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [from.toIso8601String(), to.toIso8601String()],
    );

    return {
      for (final row in rows)
        row['category'] as String: (row['total'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<double>> monthlyTotalsForYear(int year) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''
      SELECT strftime('%m', createdAt) as month, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y', createdAt) = ?
      GROUP BY month
      ORDER BY month
      ''',
      [year.toString().padLeft(4, '0')],
    );

    final totals = List<double>.filled(12, 0);
    for (final row in rows) {
      final month = int.parse(row['month'] as String);
      totals[month - 1] = (row['total'] as num?)?.toDouble() ?? 0;
    }
    return totals;
  }
}
