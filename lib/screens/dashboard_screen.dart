import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/frequency.dart';
import '../widgets/add_item_dialog.dart';
import 'income_list_screen.dart';
import 'expense_list_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime currentFortnightStart;

  @override
  void initState() {
    super.initState();
    currentFortnightStart = StorageService.getFortnightStart();
  }

  @override
  Widget build(BuildContext context) {
    final incomes = StorageService.getIncomes();
    final expenses = StorageService.getExpenses();

    final currentFortnightEnd = currentFortnightStart.add(const Duration(days: 13));

    // -----------------------------
    // Calculate totals per fortnight
    // -----------------------------
    final fortnightIncome = incomes.fold(0.0, (sum, i) => sum + i.fortnightAmount);
    final fortnightExpense = expenses.fold(0.0, (sum, e) => sum + e.fortnightCost);

    final savings = fortnightIncome * 0.2;
    final remaining = fortnightIncome - fortnightExpense - savings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {
                currentFortnightStart = StorageService.getFortnightStart();
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${_formatDate(currentFortnightStart)} - ${_formatDate(currentFortnightEnd)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentFortnightStart =
                          currentFortnightStart.subtract(const Duration(days: 14));
                    });
                  },
                  child: const Text('◀ Previous'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentFortnightStart =
                          currentFortnightStart.add(const Duration(days: 14));
                    });
                  },
                  child: const Text('Next ▶'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _card(
                    context,
                    'Income',
                    fortnightIncome,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IncomeListScreen()),
                    ).then((_) => setState(() {})),
                  ),
                  _card(
                    context,
                    'Expenses',
                    fortnightExpense,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpenseListScreen()),
                    ).then((_) => setState(() {})),
                  ),
                  _card(context, 'Savings', savings, null),
                  _card(context, 'Remaining', remaining, null),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (v) {
          if (v == 'income') _addIncome(context);
          if (v == 'expense') _addExpense(context);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'income', child: Text('Add Income')),
          PopupMenuItem(value: 'expense', child: Text('Add Expense')),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _card(
      BuildContext context, String title, double value, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: onTap != null ? const Text('Tap to view items') : null,
        trailing: Text('\$${value.toStringAsFixed(2)}'),
        onTap: onTap,
      ),
    );
  }

  void _addIncome(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        title: 'Add Income',
        onSave: (name, category, amount, freq) {
          StorageService.saveIncome(
            Income(
              name: name,
              category: category,
              amount: amount,
              frequency: freq,
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  void _addExpense(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        title: 'Add Expense',
        onSave: (name, category, amount, freq) {
          StorageService.saveExpense(
            Expense(
              name: name,
              category: category,
              amount: amount,
              frequency: freq,
            ),
          );
          setState(() {});
        },
      ),
    );
  }
}
