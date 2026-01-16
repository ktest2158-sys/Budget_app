import 'package:flutter/material.dart';
import '../models/frequency.dart';
import '../services/storage_service.dart';

typedef OnSaveCallback = void Function(
    String name, String category, double amount, Frequency frequency);

class EditItemDialog extends StatefulWidget {
  final String title;
  final String name;
  final String category;
  final double amount;
  final Frequency frequency;
  final OnSaveCallback onSave;
  final bool isExpense;

  const EditItemDialog({
    super.key,
    required this.title,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.onSave,
    this.isExpense = false,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late Frequency _selectedFrequency;
  late List<String> categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _amountController = TextEditingController(text: widget.amount.toString());
    _selectedFrequency = widget.frequency;

    categories = widget.isExpense
        ? StorageService.getExpenseCategories()
        : ['Income']; // placeholder
    _selectedCategory = widget.category.isNotEmpty
        ? widget.category
        : (categories.isNotEmpty ? categories.first : null);
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
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select category' : null,
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
