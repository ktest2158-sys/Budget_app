import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/edit_item_dialog.dart';
import '../models/frequency.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  // --- UI State: Temporary memory for "ticked" items ---
  // This is NOT saved to Hive, so it resets when you leave the screen
  // or when the app rebuilds for a new fortnight.
  final Set<String> _tickedIds = {};

  @override
  Widget build(BuildContext context) {
    final expenses = StorageService.getExpenses();

    // -----------------------------
    // Totals per category (fortnight)
    // -----------------------------
    final categoryTotals = <String, double>{};
    for (var e in expenses) {
      categoryTotals[e.category] =
          (categoryTotals[e.category] ?? 0) + e.fortnightCost;
    }

    // -----------------------------
    // Total expenses (fortnight)
    // -----------------------------
    final totalFortnight =
        expenses.fold(0.0, (sum, e) => sum + e.fortnightCost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          // Manual clear button if you want to reset during the same session
          if (_tickedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _tickedIds.clear()),
              tooltip: 'Clear Ticks',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Category totals
          ...categoryTotals.entries.map(
            (e) => ListTile(
              title: Text(
                e.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text('\$${e.value.toStringAsFixed(2)} / fortnight'),
            ),
          ),
          const Divider(),

          // Individual expense items
          ...expenses.map(
            (expense) {
              final bool isTicked = _tickedIds.contains(expense.id);

              return Card(
                // HIGHLIGHT: Background turns light purple when ticked
                color: isTicked ? Colors.deepPurple.withOpacity(0.15) : null,
                elevation: isTicked ? 0 : 1, 
                child: ListTile(
                  onTap: () {
                    // Toggles the "ticked" highlight locally
                    setState(() {
                      if (isTicked) {
                        _tickedIds.remove(expense.id);
                      } else {
                        _tickedIds.add(expense.id);
                      }
                    });
                  },
                  onLongPress: () => _editExpense(context, expense),
                  title: Text(
                    expense.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${expense.category} • '
                    '\$${expense.amount.toStringAsFixed(2)} / ${expense.frequency.label} '
                    '• Fortnight: \$${expense.fortnightCost.toStringAsFixed(2)}',
                  ),
                  trailing: isTicked
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await StorageService.deleteExpense(expense.id);
                            setState(() {});
                          },
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Total
          ListTile(
            title: const Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing:
                Text('\$${totalFortnight.toStringAsFixed(2)} / fortnight'),
          ),
        ],
      ),
    );
  }

  void _addExpense(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        title: 'Add Expense',
        isExpense: true,
        onSave: (name, category, amount, freq) async {
          await StorageService.saveExpense(
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

  void _editExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (_) => EditItemDialog(
        title: 'Edit Expense',
        name: expense.name,
        category: expense.category,
        amount: expense.amount,
        frequency: expense.frequency,
        isExpense: true,
        onSave: (name, category, amount, freq) async {
          await StorageService.saveExpense(
            Expense(
              id: expense.id,
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
