import 'package:flutter/material.dart';

// Category model
class Category {
  String name;
  String type; // "Income" or "Expense"

  Category({required this.name, required this.type});
}

class SettingsScreen extends StatefulWidget {
  final List<Category> userCategories;
  final Future<void> Function()? uploadCSV;
  final Future<void> Function()? clearAll;
  final Future<void> Function(DateTime)? clearMonth;

  const SettingsScreen({
    super.key,
    required this.userCategories,
    this.uploadCSV,
    this.clearAll,
    this.clearMonth,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<Category> categories;
  final TextEditingController newCatCtrl = TextEditingController();
  String selectedType = "Income";

  @override
  void initState() {
    super.initState();
    categories = List.from(widget.userCategories);
    if (categories.isNotEmpty) {
      selectedType = categories.first.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- Category management ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newCatCtrl,
                    decoration: const InputDecoration(labelText: 'New Category'),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: "Income", child: Text("Income")),
                    DropdownMenuItem(value: "Expense", child: Text("Expense")),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedType = v);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final name = newCatCtrl.text.trim();
                    if (name.isNotEmpty &&
                        !categories.any((c) => c.name == name)) {
                      setState(() {
                        categories.add(Category(name: name, type: selectedType));
                        newCatCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return ListTile(
                    title: Text('${cat.name} | ${cat.type}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => categories.removeAt(i));
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, categories),
              child: const Text('Save Categories & Back'),
            ),
            const Divider(height: 30),
            // --- CSV operations ---
            ElevatedButton(
              onPressed: widget.uploadCSV,
              child: const Text('Upload CSV'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: widget.clearAll,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear All Transactions'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (widget.clearMonth != null) {
                  final now = DateTime.now();
                  widget.clearMonth!(now);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Clear Current Month'),
            ),
          ],
        ),
      ),
    );
  }
}
