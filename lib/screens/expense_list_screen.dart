import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../models/frequency.dart';

class ExpenseListScreen extends StatefulWidget {
  final int fortnightOffset;
  const ExpenseListScreen({super.key, required this.fortnightOffset});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late List<Expense> templates;
  late List<Expense> paidInFortnight;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final range = StorageService.getFortnightRange(widget.fortnightOffset);

    final allExpenses = StorageService.getExpenses();

    paidInFortnight = allExpenses
        .where((exp) =>
            !exp.isTemplate &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    templates = StorageService.getTemplates().where((template) {
      // Hide template if already paid
      return !paidInFortnight.any((paid) => paid.name == template.name);
    }).toList();

    setState(() {});
  }

  void _checkOffExpense(Expense template) async {
    await StorageService.checkOffExpense(template, widget.fortnightOffset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.name} checked off!')),
    );
    _loadExpenses(); // refresh UI
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
      appBar: AppBar(title: const Text('Manage Expenses')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // --- Remaining Templates ---
          if (templates.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "REMAINING BILLS",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            ...templates.map((template) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.check_box_outline_blank),
                      onPressed: () => _checkOffExpense(template),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.name,
                            style: const TextStyle(fontSize: 16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${template.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16)),
                            Text(_frequencyText(template.frequency),
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          const Divider(height: 40, thickness: 1),

          // --- Paid Expenses ---
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "PAID & COMPLETED",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          if (paidInFortnight.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No bills paid yet for this period.",
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ...paidInFortnight.map((expense) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.name,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16)),
                          Text(_frequencyText(expense.frequency),
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () async {
                      await StorageService.deleteExpense(expense.id);
                      _loadExpenses();
                    },
                  ),
                ),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
