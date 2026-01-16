import 'package:flutter/material.dart';
import '../models/frequency.dart';
import '../services/storage_service.dart';

typedef OnSaveCallback = void Function(
    String name, String category, double amount, Frequency frequency);

class AddItemDialog extends StatefulWidget {
  final String title;
  final OnSaveCallback onSave;
  final String? initialName;
  final String? initialCategory;
  final double? initialAmount;
  final Frequency? initialFrequency;
  final bool isExpense;

  const AddItemDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialName,
    this.initialCategory,
    this.initialAmount,
    this.initialFrequency,
    this.isExpense = false,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late Frequency _selectedFrequency;
  late List<String> categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _amountController =
        TextEditingController(text: widget.initialAmount?.toString() ?? '');
    _selectedFrequency = widget.initialFrequency ?? Frequency.weekly;

    // Load categories only for expenses
    categories = widget.isExpense
        ? StorageService.getExpenseCategories()
        : ['Income']; // placeholder for income
    _selectedCategory =
        widget.initialCategory ?? (categories.isNotEmpty ? categories.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            if (widget.isExpense)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (v) => v == null || v.isEmpty ? 'Select category' : null,
              )
            else
              TextFormField(
                initialValue: 'Income',
                enabled: false,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (v) =>
                  v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Frequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: Frequency.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFrequency = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _selectedCategory ?? 'Miscellaneous',
                double.parse(_amountController.text),
                _selectedFrequency,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
