import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../models/frequency.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final int fortnightOffset;
  const ExpenseListScreen({super.key, required this.fortnightOffset});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  Widget build(BuildContext context) {
    final range = StorageService.getFortnightRange(widget.fortnightOffset);
    
    // 1. Get ONLY actual expenses for this fortnight
    final allExpenses = StorageService.getExpenses();
    final paidInFortnight = allExpenses.where((exp) => 
      !exp.isTemplate && 
      exp.date != null && 
      exp.date!.isAfter(range['start']!.subtract(const Duration(seconds: 1))) && 
      exp.date!.isBefore(range['end']!.add(const Duration(seconds: 1)))
    ).toList();

    // 2. ✅ THE FIX: Get Master Templates but HIDE them if they are already in the 'paid' list
    final templates = StorageService.getTemplates().where((template) {
      // If any 'paid' expense has the same name as this template, hide the template
      bool alreadyPaid = paidInFortnight.any((paid) => paid.name == template.name);
      return !alreadyPaid;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context, range),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          // --- SECTION: REMAINING TO PAY ---
          if (templates.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text("REMAINING BILLS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
            ),
            ...templates.map((template) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.radio_button_unchecked, color: Colors.blue),
                title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text("\$${template.amount.toStringAsFixed(2)}"),
                onTap: () async {
                  // ✅ When tapped, it creates a 'Paid' version and disappears from here
                  await StorageService.checkOffExpense(template, widget.fortnightOffset);
                  setState(() {}); 
                },
              ),
            )),
          ],

          const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),

          // --- SECTION: COMPLETED ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("PAID & COMPLETED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
          ),
          if (paidInFortnight.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No bills paid yet for this period.", style: TextStyle(color: Colors.grey)),
            )),
          ...paidInFortnight.map((expense) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(expense.name, style: const TextStyle(color: Colors.grey)),
            subtitle: Text("\$${expense.amount.toStringAsFixed(2)}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await StorageService.deleteExpense(expense.id);
                setState(() {}); // Deleting a paid item makes it reappear in 'Remaining'
              },
            ),
            onTap: () => _navigateToEdit(context, expense),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- HELPERS (Keep your Add/Edit working) ---

  void _navigateToAddExpense(BuildContext context, Map<String, DateTime> range) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddItemScreen(
        title: 'Add Expense',
        onSave: (name, category, amount, freq) async {
          bool isOneOff = (freq == Frequency.oneOff);
          await StorageService.saveExpense(Expense(
            name: name, category: category, amount: amount,
            frequency: freq, isTemplate: !isOneOff, 
            date: isOneOff ? range['start'] : null, 
          ));
          setState(() {});
        },
      ),
    ));
  }

  void _navigateToEdit(BuildContext context, Expense expense) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EditItemScreen(
        title: "Edit Paid Expense",
        name: expense.name,
        category: expense.category,
        amount: expense.amount,
        frequency: expense.frequency,
        onSave: (name, cat, amt, freq) async {
          final updated = Expense(
            id: expense.id, name: name, category: cat,
            amount: amt, frequency: freq, isTemplate: false, date: expense.date,
          );
          await StorageService.saveExpense(updated);
          setState(() {});
        },
      ),
    ));
  }
}