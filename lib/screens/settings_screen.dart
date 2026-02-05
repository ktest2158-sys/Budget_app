import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'expense_category_screen.dart';
import 'templates_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = StorageService.getExpenseCategories();
    final templates = StorageService.getTemplates();
    final incomes = StorageService.getIncomes()
        .where((inc) => inc.date == StorageService.appStartDate)
        .toList();
    final currentStart = StorageService.getFortnightStart();
    final savingsPercentage = StorageService.getSavingsPercent(); // FIXED
    final minimumRemaining = StorageService.getMinRemaining();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Budget Period Section
          const Text(
            'Budget Period',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Fortnight Start Date'),
              subtitle: Text(
                'Current: ${currentStart.day}/${currentStart.month}/${currentStart.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
          ),
          const SizedBox(height: 24),

          // Categories Section
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: const Text('Manage Expense Categories'),
              subtitle: Text('${categories.length} categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpenseCategoryScreen(),
                  ),
                );
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 24),

          // Recurring Templates Section
          const Text(
            'Recurring Templates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.red),
                  title: const Text('Manage Recurring Expenses'),
                  subtitle: Text('${templates.length} templates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TemplatesScreen(isExpense: true),
                      ),
                    );
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.green),
                  title: const Text('Manage Recurring Income'),
                  subtitle: Text('${incomes.length} templates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TemplatesScreen(isExpense: false),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget Rules Section
          const Text(
            'Budget Rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.savings, color: Colors.green),
                  title: const Text('Maximum Savings Percentage'),
                  subtitle: Text(
                    '${savingsPercentage.toStringAsFixed(0)}% of income',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editSavingsPercentage,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet,
                      color: Colors.blue),
                  title: const Text('Minimum Remaining Amount'),
                  subtitle: Text('\$${minimumRemaining.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editMinimumRemaining,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management Section
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.orange),
                  title: const Text('Reset Budget Rules to Default'),
                  subtitle: const Text(
                      'Restore default savings and minimum remaining'),
                  onTap: _resetToDefaults,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all income and expense records'),
                  onTap: _confirmClearAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // Actions
  // =============================
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: StorageService.getFortnightStart(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      await StorageService.saveFortnightStart(picked);
      setState(() {});
    }
  }

  Future<void> _editSavingsPercentage() async {
    final currentValue = StorageService.getSavingsPercent(); // FIXED
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(0));

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Maximum Savings Percentage'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Percentage',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final percentage = double.tryParse(result);
    if (percentage == null || percentage < 0 || percentage > 100) return;

    await StorageService.saveSavingsPercent(percentage); // FIXED
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editMinimumRemaining() async {
    final currentValue = StorageService.getMinRemaining();
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(0));

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Minimum Remaining Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final amount = double.tryParse(result);
    if (amount == null || amount < 0) return;

    await StorageService.saveMinRemaining(amount);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Reset savings percentage to 20% and minimum remaining to \$300?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await StorageService.resetToDefaults(); // FIXED
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _confirmClearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all income and expense records. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (var income in StorageService.getIncomes()) {
      await StorageService.deleteIncome(income.id);
    }
    for (var expense in StorageService.getExpenses()) {
      await StorageService.deleteExpense(expense.id);
    }

    if (!mounted) return;
    setState(() {});
  }
}
