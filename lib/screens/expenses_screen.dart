import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/expense_categories.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import '../utils/financial_year.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _db = DatabaseService.instance;
  final _report = ReportService();

  DateTimeRange? _range;
  String? _category;
  late Future<List<Expense>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant ExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _load();
    }
  }

  Future<List<Expense>> _load() {
    return _db.getExpenses(
      from: _range?.start,
      to: _range?.end,
      category: _category,
    );
  }

  Future<void> _applyFilter() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        _range = selected;
        _future = _load();
      });
    }
  }

  Future<void> _export(String reportType) async {
    final now = DateTime.now();

    DateTime from;
    DateTime to;

    if (reportType == 'daily') {
      from = DateTime(now.year, now.month, now.day);
      to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (reportType == 'monthly') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      final fy = FinancialYear.forDate(now);
      from = fy.start;
      to = fy.end;
    }

    final expenses = await _db.getExpenses(from: from, to: to, category: _category);
    final file = await _report.exportExpenses(
      reportName: '${reportType}_report',
      expenses: expenses,
      filePath: 'report_${reportType}_${now.millisecondsSinceEpoch}.xlsx',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report saved: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: _applyFilter, child: const Text('Date range')),
              DropdownButton<String?>(
                value: _category,
                hint: const Text('Category'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                  ...expenseCategories.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
                ],
                onChanged: (value) => setState(() {
                  _category = value;
                  _future = _load();
                }),
              ),
              PopupMenuButton<String>(
                onSelected: _export,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'daily', child: Text('Export daily Excel')),
                  PopupMenuItem(value: 'monthly', child: Text('Export monthly Excel')),
                  PopupMenuItem(value: 'fy', child: Text('Export financial year Excel')),
                ],
                child: const Chip(label: Text('Export reports')),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Expense>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final expenses = snapshot.data!;
              if (expenses.isEmpty) return const Center(child: Text('No expenses found'));

              return ListView.separated(
                itemBuilder: (context, index) {
                  final exp = expenses[index];
                  return ListTile(
                    title: Text(exp.category),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy, hh:mm a').format(exp.createdAt)} · ${exp.paymentMode.name.toUpperCase()}\n${exp.note ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: Text('₹ ${exp.amount.toStringAsFixed(2)}'),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: expenses.length,
              );
            },
          ),
        ),
      ],
    );
  }
}
