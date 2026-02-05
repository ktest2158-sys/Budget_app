import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/frequency.dart';
import '../models/income.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Settings
  DateTime _fortnightStart = DateTime.now();
  double _minRemaining = 300.0;
  double _savingsPercent = 20.0;

  // Temporary storage for templates
  final List<Map<String, dynamic>> _incomeTemplates = [];
  final List<Map<String, dynamic>> _expenseTemplates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 4,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildSettingsPage(),
                  _buildIncomePage(),
                  _buildExpensesPage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 100,
            color: Colors.blue[700],
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Budget App!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your personal budget tracker in just a few steps.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem(
                  Icons.calendar_today,
                  'Fortnight-based budgeting',
                ),
                _buildFeatureItem(
                  Icons.repeat,
                  'Recurring income & expenses',
                ),
                _buildFeatureItem(
                  Icons.pie_chart,
                  'Visual spending analytics',
                ),
                _buildFeatureItem(
                  Icons.savings,
                  'Automatic savings calculation',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Configure Your Budget',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your budget rules and preferences',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text('Fortnight Start Date'),
            subtitle: Text(
              '${_fortnightStart.day}/${_fortnightStart.month}/${_fortnightStart.year}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fortnightStart,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() => _fortnightStart = picked);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Minimum Remaining Buffer (\$)',
                    helperText: 'Amount to keep as safety buffer',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: _minRemaining.toStringAsFixed(0),
                  ),
                  onChanged: (v) {
                    _minRemaining = double.tryParse(v) ?? 300.0;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Savings Percentage (%)',
                    helperText: 'Max % of income to save',
                    prefixIcon: Icon(Icons.savings),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: _savingsPercent.toStringAsFixed(0),
                  ),
                  onChanged: (v) {
                    _savingsPercent = double.tryParse(v) ?? 20.0;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can change these settings later in the Settings screen',
                  style: TextStyle(color: Colors.amber[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Add Recurring Income',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your regular income sources',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addIncomeTemplate,
          icon: const Icon(Icons.add),
          label: const Text('Add Income Source'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        if (_incomeTemplates.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No income sources added yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          ..._incomeTemplates.asMap().entries.map((entry) {
            final index = entry.key;
            final income = entry.value;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title: Text(income['name']),
                subtitle: Text(
                  '${income['category']} • \$${income['amount'].toStringAsFixed(2)} (${income['frequency'].label})',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _incomeTemplates.removeAt(index));
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can add more income sources later or skip this step',
                  style: TextStyle(color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Add Recurring Expenses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your regular bills and expenses',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addExpenseTemplate,
          icon: const Icon(Icons.add),
          label: const Text('Add Recurring Expense'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        if (_expenseTemplates.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recurring expenses added yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          ..._expenseTemplates.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.red),
                title: Text(expense['name']),
                subtitle: Text(
                  '${expense['category']} • \$${expense['amount'].toStringAsFixed(2)} (${expense['frequency'].label})',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _expenseTemplates.removeAt(index));
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can add more expenses later or skip this step',
                  style: TextStyle(color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentPage == 3 ? _finishOnboarding : _nextPage,
              child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _addIncomeTemplate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _QuickIncomeDialog(),
    );

    if (result != null) {
      setState(() => _incomeTemplates.add(result));
    }
  }

  Future<void> _addExpenseTemplate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _QuickExpenseDialog(),
    );

    if (result != null) {
      setState(() => _expenseTemplates.add(result));
    }
  }

  Future<void> _finishOnboarding() async {
    // Save settings
    await StorageService.saveFortnightStart(_fortnightStart);
    await StorageService.saveMinRemaining(_minRemaining);
    await StorageService.saveSavingsPercent(_savingsPercent);

    // Save income templates
    for (var income in _incomeTemplates) {
      await StorageService.saveIncome(Income(
        name: income['name'],
        category: income['category'],
        amount: income['amount'],
        frequency: income['frequency'],
        date: StorageService.appStartDate,
      ));
    }

    // Save expense templates
    for (var expense in _expenseTemplates) {
      await StorageService.addExpense(
        name: expense['name'],
        category: expense['category'],
        amount: expense['amount'],
        frequency: expense['frequency'],
        isTemplate: true,
      );
    }

    // Mark onboarding as complete
    await StorageService.completeFirstLaunch();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }
}

// Quick Income Dialog
class _QuickIncomeDialog extends StatefulWidget {
  const _QuickIncomeDialog();

  @override
  State<_QuickIncomeDialog> createState() => _QuickIncomeDialogState();
}

class _QuickIncomeDialogState extends State<_QuickIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Salary');
  final _amountController = TextEditingController();
  Frequency _frequency = Frequency.fortnightly;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income Source'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (\$)'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Invalid' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: Frequency.values.map((f) {
                return DropdownMenuItem(value: f, child: Text(f.label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'category': _categoryController.text.trim(),
                'amount': double.parse(_amountController.text),
                'frequency': _frequency,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Quick Expense Dialog
class _QuickExpenseDialog extends StatefulWidget {
  const _QuickExpenseDialog();

  @override
  State<_QuickExpenseDialog> createState() => _QuickExpenseDialogState();
}

class _QuickExpenseDialogState extends State<_QuickExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _category;
  Frequency _frequency = Frequency.fortnightly;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = StorageService.getExpenseCategories();
    _category = _categories.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Recurring Expense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (\$)'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Invalid' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: Frequency.values.map((f) {
                return DropdownMenuItem(value: f, child: Text(f.label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'category': _category!,
                'amount': double.parse(_amountController.text),
                'frequency': _frequency,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
