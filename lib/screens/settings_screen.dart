import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // MATCHED: Using your uploaded function name
    final categories = StorageService.getExpenseCategories();
    final currentStart = StorageService.getFortnightStart();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Budget Period',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('Fortnight Start Date'),
            subtitle: Text(
                'Current: ${currentStart.day}/${currentStart.month}/${currentStart.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            'Expense Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: 'New Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...categories.map((cat) => ListTile(
                title: Text(cat),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(cat),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: StorageService.getFortnightStart(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      // MATCHED: Using your uploaded function name
      await StorageService.saveFortnightStart(picked);
      setState(() {});
    }
  }

  void _addCategory() {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty) {
      // MATCHED: Using your uploaded function name
      StorageService.saveExpenseCategory(name);
      _categoryController.clear();
      setState(() {});
    }
  }

  void _deleteCategory(String category) {
    // MATCHED: Using your uploaded function name
    StorageService.deleteExpenseCategory(category);
    setState(() {});
  }
}