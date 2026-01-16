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
          // Reset button to clear all ticks permanently for the current session
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              for (var e in expenses) {
                if (e.isChecked) {
                  e.isChecked = false;
                  await StorageService.saveExpense(e);
                }
              }
              setState(() {});
            },
            tooltip: 'Reset Ticks',
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
              return Card(
                // Use the saved isChecked status from the database
                color: expense.isChecked ? Colors.deepPurple.withOpacity(0.15) : null,
                elevation: expense.isChecked ? 0 : 1,
                child: ListTile(
                  onTap: () async {
                    // Toggle the value in the model
                    setState(() {
                      expense.isChecked = !expense.isChecked;
                    });
                    // Save the change to Hive so it persists until you reset it
                    await StorageService.saveExpense(expense);
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
                  trailing: expense.isChecked
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
              // New items start unchecked by default
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
          // Update existing object properties
          expense.name = name;
          expense.category = category;
          expense.amount = amount;
          expense.frequency = freq;
          
          await StorageService.saveExpense(expense);
          setState(() {});
        },
      ),
    );
  }
}
