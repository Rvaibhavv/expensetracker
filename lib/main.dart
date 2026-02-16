import 'package:flutter/material.dart';

import 'screens/add_expense_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _refreshToken = 0;

  void _refresh() => setState(() => _refreshToken++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(refreshToken: _refreshToken),
      AddExpenseScreen(onSaved: _refresh),
      ExpensesScreen(refreshToken: _refreshToken),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Trading Expense Tracker')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
        ],
      ),
    );
  }
}
