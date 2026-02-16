import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/financial_year.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = DatabaseService.instance;

  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _load();
    }
  }

  Future<_DashboardData> _load() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    final fy = FinancialYear.forDate(now);

    final today = await db.sumExpenses(from: todayStart, to: todayEnd);
    final month = await db.sumExpenses(from: monthStart, to: monthEnd);
    final year = await db.sumExpenses(from: yearStart, to: yearEnd);
    final fyTotal = await db.sumExpenses(from: fy.start, to: fy.end);
    final categoryTotals = await db.categoryTotals(from: fy.start, to: fy.end);
    final monthlyTrend = await db.monthlyTotalsForYear(now.year);

    return _DashboardData(
      todayTotal: today,
      monthTotal: month,
      yearTotal: year,
      fyTotal: fyTotal,
      categoryTotals: categoryTotals,
      fyLabel: fy.label,
      monthlyTrend: monthlyTrend,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final topThree = data.categoryTotals.entries.take(3).toList();
        final highestCategory = data.categoryTotals.entries.isNotEmpty
            ? data.categoryTotals.entries.first
            : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(title: 'Today', value: data.todayTotal),
                _MetricCard(title: 'This month', value: data.monthTotal),
                _MetricCard(title: 'This year', value: data.yearTotal),
                _MetricCard(title: 'FY ${data.fyLabel}', value: data.fyTotal),
              ],
            ),
            if (highestCategory != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  title: const Text('Highest spending category'),
                  subtitle: Text(highestCategory.key),
                  trailing: Text('₹ ${highestCategory.value.toStringAsFixed(2)}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top 3 categories', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final item in topThree)
                      ListTile(
                        dense: true,
                        title: Text(item.key),
                        trailing: Text('₹ ${item.value.toStringAsFixed(2)}'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 230,
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                              return Text(labels[value.toInt()]);
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        data.monthlyTrend.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [BarChartRodData(toY: data.monthlyTrend[i], width: 10)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category-wise FY distribution',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: _pieSections(data.categoryTotals),
                          centerSpaceRadius: 30,
                          sectionsSpace: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, double> totals) {
    final colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.red, Colors.brown];
    final entries = totals.entries.toList();
    if (entries.isEmpty) {
      return [
        PieChartSectionData(value: 1, title: 'No data', color: Colors.grey, radius: 70),
      ];
    }

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return PieChartSectionData(
        value: entry.value,
        title: entry.key.length > 12 ? '${entry.key.substring(0, 12)}…' : entry.key,
        color: colors[index % colors.length],
        radius: 70,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('₹ ${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.todayTotal,
    required this.monthTotal,
    required this.yearTotal,
    required this.fyTotal,
    required this.categoryTotals,
    required this.fyLabel,
    required this.monthlyTrend,
  });

  final double todayTotal;
  final double monthTotal;
  final double yearTotal;
  final double fyTotal;
  final Map<String, double> categoryTotals;
  final String fyLabel;
  final List<double> monthlyTrend;
}
