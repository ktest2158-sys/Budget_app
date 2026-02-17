import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../models/frequency.dart';
import 'add_item_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final int fortnightOffset;
  const ExpenseListScreen({super.key, required this.fortnightOffset});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late List<Expense> regularTemplates;
  late List<Expense> savingsTemplates;
  late List<Expense> paidInFortnight;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    final range = StorageService.getFortnightRange(widget.fortnightOffset);
    final allExpenses = StorageService.getExpenses();

    // All non-template expenses checked off this fortnight (regular + savings contributions + withdrawals)
    paidInFortnight = allExpenses
        .where((exp) =>
            !exp.isTemplate &&
            exp.date != null &&
            exp.date!.isAfter(
                range['start']!.subtract(const Duration(seconds: 1))) &&
            exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1))))
        .toList();

    final paidNames = paidInFortnight.map((e) => e.name).toSet();

    // Regular expense templates not yet paid this fortnight
    regularTemplates = StorageService.getTemplates()
        .where((t) => !t.isSavings && !paidNames.contains(t.name))
        .toList();

    // Savings templates not yet contributed this fortnight
    savingsTemplates = StorageService.getTemplates()
        .where((t) => t.isSavings && !paidNames.contains(t.name))
        .toList();

    setState(() {});
  }

  void _checkOffExpense(Expense template) async {
    await StorageService.checkOffExpense(template, widget.fortnightOffset);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.name} checked off!')),
    );
    _loadExpenses();
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

  // ✅ Add one-off expense with optional savings withdrawal
  Future<void> _addOneOffExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          title: "Add One-Off Expense",
          onSave: (name, category, amount, frequency,
              {bool isSavings = false,
              bool isSavingsWithdrawal = false,
              String? savingsBucket}) async {
            await StorageService.addExpense(
              name: name,
              category: category,
              amount: amount,
              frequency: frequency,
              isTemplate: false,
              date: DateTime.now(),
              isSavings: isSavings,
              isSavingsWithdrawal: isSavingsWithdrawal,
              savingsBucket: savingsBucket,
            );
          },
          showSavingsWithdrawalOption: true, // ✅ Enable withdrawal UI
        ),
      ),
    );
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addOneOffExpense,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ─── REMAINING BILLS ───
          if (regularTemplates.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "REMAINING BILLS",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            ...regularTemplates.map((template) => Card(
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

          // ─── SAVINGS TO CONTRIBUTE ───
          if (savingsTemplates.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "SAVINGS TO CONTRIBUTE",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            ...savingsTemplates.map((template) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.indigo[50],
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.savings_outlined,
                          color: Colors.indigo),
                      onPressed: () => _checkOffExpense(template),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
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

          // ─── PAID & COMPLETED ───
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
          ...paidInFortnight.map((expense) {
            final isSavings = expense.isSavings;
            final isWithdrawal = expense.isSavingsWithdrawal;

            // Display label for withdrawals: "BucketName · description"
            final displayName = isWithdrawal && expense.savingsBucket != null
                ? '${expense.savingsBucket} · ${expense.name}'
                : expense.name;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  isSavings
                      ? Icons.savings
                      : isWithdrawal
                          ? Icons.arrow_upward
                          : Icons.check_circle,
                  color: isSavings
                      ? Colors.indigo
                      : isWithdrawal
                          ? Colors.orange
                          : Colors.green,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
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
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await StorageService.deleteExpense(expense.id);
                    _loadExpenses();
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
