import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/income.dart';
import '../models/frequency.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  @override
  Widget build(BuildContext context) {
    final incomes = StorageService.getIncomes();

    // Total per category (fortnight)
    final categoryTotals = <String, double>{};
    for (var i in incomes) {
      categoryTotals[i.category] =
          (categoryTotals[i.category] ?? 0) + i.fortnightAmount;
    }

    // Total income (fortnight)
    final totalFortnightIncome =
        incomes.fold(0.0, (sum, i) => sum + i.fortnightAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addIncome(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Show totals per category
          ...categoryTotals.entries.map(
            (e) => ListTile(
              title:
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('\$${e.value.toStringAsFixed(2)} / fortnight'),
            ),
          ),
          const Divider(),
          // Show individual items
          ...incomes.map(
            (income) => Card(
              child: ListTile(
                title: Text(income.name),
                subtitle: Text(
                    '${income.category} • \$${income.amount.toStringAsFixed(2)} / ${income.frequency == Frequency.weekly ? 'wk' : income.frequency == Frequency.fortnightly ? 'fortnight' : income.frequency.label} • Fortnight: \$${income.fortnightAmount.toStringAsFixed(2)}'),
                onTap: () => _editIncome(context, income),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await StorageService.deleteIncome(income.id);
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('\$${totalFortnightIncome.toStringAsFixed(2)} / fortnight'),
          ),
        ],
      ),
    );
  }

  void _addIncome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          title: 'Add Income',
          onSave: (name, category, amount, freq) async {
            await StorageService.saveIncome(
              Income(name: name, category: category, amount: amount, frequency: freq),
            );
            setState(() {});
          },
        ),
      ),
    );
  }

  void _editIncome(BuildContext context, Income income) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(
          title: 'Edit Income',
          name: income.name,
          category: income.category,
          amount: income.amount,
          frequency: income.frequency,
          onSave: (name, category, amount, freq) async {
            await StorageService.saveIncome(
              Income(
                id: income.id,
                name: name,
                category: category,
                amount: amount,
                frequency: freq,
              ),
            );
            setState(() {});
          },
        ),
      ),
    );
  }
}
