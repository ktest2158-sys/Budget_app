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
  void _refresh() => setState(() {});

  void _addTemplate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          title:
              widget.isExpense ? 'Add Expense Template' : 'Add Income Template',
          showSavingsWithdrawalOption:
              false, // ✅ Templates never show withdrawal UI
          onSave: (name, category, amount, frequency,
              {bool isSavings = false,
              bool isSavingsWithdrawal = false,
              String? savingsBucket}) async {
            if (widget.isExpense) {
              await StorageService.addExpense(
                name: name,
                category: category,
                amount: amount,
                frequency: frequency,
                isTemplate: true,
                isSavings: isSavings, // ✅ Pass savings flag through
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
              isSavings: template.isSavings, // ✅ Preserve savings flag on edit
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

  String _frequencyLabel(Frequency freq) =>
      freq.name[0].toUpperCase() + freq.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final templates = widget.isExpense
        ? StorageService.getTemplates()
        : StorageService.getIncomes()
            .where((inc) => inc.date == StorageService.appStartDate)
            .toList();

    // ✅ For expense templates, split into regular and savings for visual grouping
    final regularExpenseTemplates = widget.isExpense
        ? (templates as List<Expense>).where((t) => !t.isSavings).toList()
        : <Expense>[];
    final savingsExpenseTemplates = widget.isExpense
        ? (templates as List<Expense>).where((t) => t.isSavings).toList()
        : <Expense>[];

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
          ? const Center(child: Text('No templates yet. Tap + to add one.'))
          : widget.isExpense
              ? _buildExpenseTemplateList(
                  regularExpenseTemplates, savingsExpenseTemplates)
              : _buildIncomeTemplateList(templates as List<Income>),
    );
  }

  Widget _buildExpenseTemplateList(
      List<Expense> regular, List<Expense> savings) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ─── Regular expense templates ───
        if (regular.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text('BILLS & EXPENSES',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey)),
          ),
          ...regular.map((template) => _buildExpenseCard(template)),
        ],

        // ─── Savings templates ───
        if (savings.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Text('SAVINGS BUCKETS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.indigo)),
          ),
          ...savings.map((template) => _buildExpenseCard(template)),
        ],
      ],
    );
  }

  Widget _buildExpenseCard(Expense template) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          template.isSavings ? Icons.savings : Icons.receipt_long,
          color: template.isSavings ? Colors.indigo : Colors.red,
        ),
        title: Text(template.name),
        subtitle: Text(
          '${template.category} · \$${template.amount.toStringAsFixed(2)} · ${_frequencyLabel(template.frequency)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Show savings badge
            if (template.isSavings)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo),
                ),
                child: const Text('Savings',
                    style: TextStyle(fontSize: 10, color: Colors.indigo)),
              ),
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
  }

  Widget _buildIncomeTemplateList(List<Income> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: templates.length,
      itemBuilder: (_, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: Text(template.name),
            subtitle: Text(
              '${template.category} · \$${template.amount.toStringAsFixed(2)} · ${_frequencyLabel(template.frequency)}',
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
      },
    );
  }
}
