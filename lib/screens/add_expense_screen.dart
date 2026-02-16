import 'package:flutter/material.dart';

import '../constants/expense_categories.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = expenseCategories.first;
  PaymentMode _paymentMode = PaymentMode.cash;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await DatabaseService.instance.addExpense(
      Expense(
        category: _selectedCategory,
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        paymentMode: _paymentMode,
        createdAt: _selectedDate,
      ),
    );

    if (!mounted) return;
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense saved')),
    );

    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedCategory = expenseCategories.first;
      _paymentMode = PaymentMode.cash;
      _selectedDate = DateTime.now();
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Expense type *'),
              items: expenseCategories
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ '),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter amount';
                if (double.tryParse(value.trim()) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note / description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMode>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: PaymentMode.values
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode.name.toUpperCase())))
                  .toList(),
              onChanged: (value) => setState(() => _paymentMode = value!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & time'),
              subtitle: Text(_selectedDate.toLocal().toString()),
              trailing: TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        _selectedDate.hour,
                        _selectedDate.minute,
                      );
                    });
                  }
                },
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
