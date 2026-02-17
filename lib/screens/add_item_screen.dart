import 'package:flutter/material.dart';
import '../models/frequency.dart';
import '../services/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  final String title;
  final Function(
    String name,
    String category,
    double amount,
    Frequency frequency, {
    bool isSavings,
    bool isSavingsWithdrawal,
    String? savingsBucket,
  }) onSave;

  // ✅ When true, shows the "Paid from savings?" withdrawal UI (one-off expenses only)
  final bool showSavingsWithdrawalOption;

  const AddItemScreen({
    super.key,
    required this.title,
    required this.onSave,
    this.showSavingsWithdrawalOption = false,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedCategory;
  Frequency _selectedFrequency = Frequency.fortnightly;

  late List<String> _categories;

  // ✅ Savings contribution toggle (for expense templates)
  bool _isSavings = false;

  // ✅ Savings withdrawal fields (for one-off expenses)
  bool _isSavingsWithdrawal = false;
  String? _selectedSavingsBucket;
  late List<String> _savingsBuckets;

  @override
  void initState() {
    super.initState();
    _categories = StorageService.getExpenseCategories();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
    _savingsBuckets = StorageService.getSavingsBucketNames();
    if (_savingsBuckets.isNotEmpty) {
      _selectedSavingsBucket = _savingsBuckets.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ─── Name ───
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ─── Category (hidden if savings withdrawal — no category needed) ───
              if (!_isSavingsWithdrawal) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // ─── Frequency ───
              DropdownButtonFormField<Frequency>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: Frequency.values.map((Frequency freq) {
                  return DropdownMenuItem<Frequency>(
                    value: freq,
                    child: Text(
                        freq.name[0].toUpperCase() + freq.name.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedFrequency = value);
                },
              ),
              const SizedBox(height: 16),

              // ─── Amount ───
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => double.tryParse(value ?? '') == null
                    ? 'Enter a valid number'
                    : null,
              ),
              const SizedBox(height: 20),

              // ─── Savings Contribution toggle (shown when NOT a one-off/withdrawal screen) ───
              if (!widget.showSavingsWithdrawalOption) ...[
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.savings, color: Colors.indigo),
                  title: const Text('Savings Contribution'),
                  subtitle: const Text(
                      'Track this as a savings bucket, not a regular expense'),
                  value: _isSavings,
                  activeThumbColor: Colors.indigo,
                  onChanged: (value) => setState(() => _isSavings = value),
                ),
                const SizedBox(height: 8),
              ],

              // ─── Savings Withdrawal option (shown on one-off expense screen) ───
              if (widget.showSavingsWithdrawalOption) ...[
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      const Icon(Icons.arrow_upward, color: Colors.orange),
                  title: const Text('Paid from Savings'),
                  subtitle: const Text(
                      'Deduct this payment from one of your savings buckets'),
                  value: _isSavingsWithdrawal,
                  activeThumbColor: Colors.orange,
                  onChanged: _savingsBuckets.isEmpty
                      ? null // Disable if no savings buckets exist
                      : (value) => setState(() => _isSavingsWithdrawal = value),
                ),
                // Show "no buckets" hint if toggle would be useful but there's nothing to select
                if (_savingsBuckets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      'Add savings contribution templates first to use this feature.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                // ─── Bucket dropdown (appears when withdrawal toggle is on) ───
                if (_isSavingsWithdrawal && _savingsBuckets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSavingsBucket,
                    decoration: const InputDecoration(
                      labelText: 'Savings Bucket',
                      prefixIcon: Icon(Icons.savings, color: Colors.indigo),
                      border: OutlineInputBorder(),
                    ),
                    items: _savingsBuckets.map((bucket) {
                      return DropdownMenuItem<String>(
                          value: bucket, child: Text(bucket));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSavingsBucket = value),
                    validator: (value) => _isSavingsWithdrawal && value == null
                        ? 'Select a savings bucket'
                        : null,
                  ),
                ],
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // ─── Save Button ───
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // For withdrawals, use "Savings" as category since it's bucket-tracked
                    final category = _isSavingsWithdrawal
                        ? 'Savings'
                        : (_selectedCategory ?? 'Miscellaneous');

                    widget.onSave(
                      _nameController.text,
                      category,
                      double.parse(_amountController.text),
                      _selectedFrequency,
                      isSavings: _isSavings,
                      isSavingsWithdrawal: _isSavingsWithdrawal,
                      savingsBucket:
                          _isSavingsWithdrawal ? _selectedSavingsBucket : null,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
