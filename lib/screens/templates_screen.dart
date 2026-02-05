import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/frequency.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class TemplatesScreen extends StatefulWidget {
  final bool isExpense;

  const TemplatesScreen({super.key, required this.isExpense});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  void _refresh() {
    setState(() {});
  }

  void _addTemplate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          title:
              widget.isExpense ? 'Add Expense Template' : 'Add Income Template',
          onSave: (name, category, amount, frequency) async {
            if (widget.isExpense) {
              await StorageService.addExpense(
                name: name,
                category: category,
                amount: amount,
                frequency: frequency,
                isTemplate: true,
              );
            } else {
              await StorageService.saveIncome(Income(
                name: name,
                category: category,
                amount: amount,
                frequency: frequency,
                date: StorageService.appStartDate,
              ));
            }
          },
        ),
      ),
    );
    _refresh();
  }

  void _editExpenseTemplate(Expense template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(
          title: 'Edit Expense Template',
          name: template.name,
          category: template.category,
          amount: template.amount,
          frequency: template.frequency,
          onSave: (name, category, amount, frequency) async {
            final updated = Expense(
              id: template.id,
              name: name,
              category: category,
              amount: amount,
              frequency: frequency,
              isTemplate: true,
            );
            await StorageService.saveExpense(updated);
          },
        ),
      ),
    );
    _refresh();
  }

  void _editIncomeTemplate(Income template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(
          title: 'Edit Income Template',
          name: template.name,
          category: template.category,
          amount: template.amount,
          frequency: template.frequency,
          onSave: (name, category, amount, frequency) async {
            final updated = Income(
              id: template.id,
              name: name,
              category: category,
              amount: amount,
              frequency: frequency,
              date: template.date,
            );
            await StorageService.saveIncome(updated);
          },
        ),
      ),
    );
    _refresh();
  }

  void _deleteExpenseTemplate(Expense template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Delete "${template.name}"? This will not affect already recorded expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteExpense(template.id);
      _refresh();
    }
  }

  void _deleteIncomeTemplate(Income template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Delete "${template.name}"? This will not affect already recorded income.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteIncome(template.id);
      _refresh();
    }
  }

  String _frequencyLabel(Frequency freq) {
    return freq.name[0].toUpperCase() + freq.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.isExpense
        ? StorageService.getTemplates()
        : StorageService.getIncomes()
            .where((inc) => inc.date == StorageService.appStartDate)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isExpense
            ? 'Recurring Expense Templates'
            : 'Recurring Income Templates'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemplate,
        child: const Icon(Icons.add),
      ),
      body: templates.isEmpty
          ? const Center(
              child: Text('No templates yet. Tap + to add one.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: templates.length,
              itemBuilder: (_, index) {
                if (widget.isExpense) {
                  final template = templates[index] as Expense;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      title: Text(template.name),
                      subtitle: Text(
                        '${template.category} • \$${template.amount.toStringAsFixed(2)} • ${_frequencyLabel(template.frequency)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editExpenseTemplate(template),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExpenseTemplate(template),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final template = templates[index] as Income;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      title: Text(template.name),
                      subtitle: Text(
                        '${template.category} • \$${template.amount.toStringAsFixed(2)} • ${_frequencyLabel(template.frequency)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editIncomeTemplate(template),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteIncomeTemplate(template),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}
