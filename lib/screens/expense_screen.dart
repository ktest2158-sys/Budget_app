import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/frequency.dart';
import '../services/storage_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late List<Expense> templates;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    templates = StorageService.getTemplates();
    setState(() {});
  }

  void _checkOffExpense(Expense template) async {
    await StorageService.checkOffExpense(template, 0); // current fortnight

    if (!mounted) return; // <- prevents using context if widget disposed

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.name} checked off!')),
    );

    _loadTemplates(); // reload to refresh UI
  }

  String _frequencyText(Frequency frequency) {
    switch (frequency) {
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.fortnightly:
        return 'Fortnightly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.quarterly:
        return 'Quarterly';
      case Frequency.annual:
        return 'Annual';
      case Frequency.oneOff:
        return 'One-Off';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final expense = templates[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Checkbox + Expense Name
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_box_outline_blank),
                      onPressed: () => _checkOffExpense(expense),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expense.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                // Line 2: Amount (left) + Frequency (right)
                Padding(
                  padding: const EdgeInsets.only(left: 48), // align under name
                  child: Row(
                    children: [
                      Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        _frequencyText(expense.frequency),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(), // optional: separates expenses
              ],
            ),
          );
        },
      ),
    );
  }
}
