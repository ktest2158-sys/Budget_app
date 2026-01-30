import 'package:flutter/material.dart';
import '../models/frequency.dart';
import '../services/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  final String title;
  final Function(
      String name, String category, double amount, Frequency frequency) onSave;

  const AddItemScreen({super.key, required this.title, required this.onSave});

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

  @override
  void initState() {
    super.initState();
    _categories = StorageService.getExpenseCategories();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // ✅ Frequency Dropdown including "One-off"
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
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => double.tryParse(value ?? '') == null
                    ? 'Enter a valid number'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(
                      _nameController.text,
                      _selectedCategory!,
                      double.parse(_amountController.text),
                      _selectedFrequency,
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
